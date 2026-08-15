import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/time/timestamp
import glot_core/helpers/timestamp_helpers
import glot_core/helpers/uuid_helpers
import glot_core/job/job_model
import glot_core/pagination_model
import youid/uuid

pub type StatusFilter {
  AllStatuses
  PendingStatus
  RunningStatus
  FailedStatus
  DoneStatus
}

pub type ListJobsRequest {
  ListJobsRequest(
    pagination: pagination_model.CursorPagination,
    status_filter: StatusFilter,
    job_type_filter: option.Option(String),
    periodic_job_id: option.Option(uuid.Uuid),
  )
}

pub type GetJobRequest {
  GetJobRequest(id: uuid.Uuid)
}

pub type CreateJobRequest {
  CreateJobRequest(
    periodic_job_id: option.Option(uuid.Uuid),
    job_type: String,
    payload: option.Option(String),
    max_attempts: Int,
    timeout_seconds: Int,
    run_at: timestamp.Timestamp,
  )
}

pub fn get_request_decoder() -> decode.Decoder(GetJobRequest) {
  use id <- decode.field("id", uuid_helpers.decoder())
  decode.success(GetJobRequest(id: id))
}

pub fn encode_get_request(request: GetJobRequest) -> json.Json {
  json.object([#("id", encode_uuid(request.id))])
}

pub fn create_request_decoder() -> decode.Decoder(CreateJobRequest) {
  use periodic_job_id <- decode.field(
    "periodicJobId",
    decode.optional(uuid_helpers.decoder()),
  )
  use job_type <- decode.field("jobType", decode.string)
  use payload <- decode.field("payload", decode.optional(decode.string))
  use max_attempts <- decode.field("maxAttempts", decode.int)
  use timeout_seconds <- decode.field("timeoutSeconds", decode.int)
  use run_at <- decode.field("runAt", timestamp_helpers.decoder())
  decode.success(CreateJobRequest(
    periodic_job_id: periodic_job_id,
    job_type: job_type,
    payload: payload,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    run_at: run_at,
  ))
}

pub fn encode_create_request(request: CreateJobRequest) -> json.Json {
  json.object([
    #("periodicJobId", json.nullable(request.periodic_job_id, encode_uuid)),
    #("jobType", json.string(request.job_type)),
    #("payload", json.nullable(request.payload, json.string)),
    #("maxAttempts", json.int(request.max_attempts)),
    #("timeoutSeconds", json.int(request.timeout_seconds)),
    #("runAt", timestamp_helpers.encode(request.run_at)),
  ])
}

pub fn list_request_decoder() -> decode.Decoder(ListJobsRequest) {
  decode.then(pagination_model.request_decoder(), fn(pagination) {
    use status_filter <- decode.field("statusFilter", status_filter_decoder())
    use job_type_filter <- decode.field(
      "jobTypeFilter",
      decode.optional(decode.string),
    )
    use periodic_job_id <- decode.field(
      "periodicJobId",
      decode.optional(uuid_helpers.decoder()),
    )
    decode.success(ListJobsRequest(
      pagination:,
      status_filter:,
      job_type_filter:,
      periodic_job_id:,
    ))
  })
}

pub fn encode_list_request(request: ListJobsRequest) -> json.Json {
  json.object(
    list.append(pagination_model.encode_request_fields(request.pagination), [
      #("statusFilter", encode_status_filter(request.status_filter)),
      #("jobTypeFilter", json.nullable(request.job_type_filter, json.string)),
      #("periodicJobId", json.nullable(request.periodic_job_id, encode_uuid)),
    ]),
  )
}

pub type JobResponse {
  JobResponse(
    id: uuid.Uuid,
    request_id: option.Option(uuid.Uuid),
    periodic_job_id: option.Option(uuid.Uuid),
    job_type: String,
    queue_name: String,
    dedupe_key: option.Option(String),
    status: String,
    attempts: Int,
    max_attempts: Int,
    timeout_seconds: Int,
    run_at: timestamp.Timestamp,
    started_at: option.Option(timestamp.Timestamp),
    lease_expires_at: option.Option(timestamp.Timestamp),
    completed_at: option.Option(timestamp.Timestamp),
    timed_out_at: option.Option(timestamp.Timestamp),
    last_error: option.Option(String),
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
    overdue: Bool,
  )
}

pub type JobsSummary {
  JobsSummary(
    total_count: Int,
    pending_count: Int,
    running_count: Int,
    failed_count: Int,
    done_count: Int,
    overdue_count: Int,
  )
}

pub type ListJobsResponse {
  ListJobsResponse(
    summary: JobsSummary,
    page: pagination_model.CursorPage(JobResponse),
  )
}

pub type JobDetailResponse {
  JobDetailResponse(
    id: uuid.Uuid,
    request_id: option.Option(uuid.Uuid),
    periodic_job_id: option.Option(uuid.Uuid),
    job_type: String,
    queue_name: String,
    dedupe_key: option.Option(String),
    payload: option.Option(String),
    status: String,
    attempts: Int,
    max_attempts: Int,
    timeout_seconds: Int,
    run_at: timestamp.Timestamp,
    started_at: option.Option(timestamp.Timestamp),
    lease_expires_at: option.Option(timestamp.Timestamp),
    completed_at: option.Option(timestamp.Timestamp),
    timed_out_at: option.Option(timestamp.Timestamp),
    last_error: option.Option(String),
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
    overdue: Bool,
  )
}

pub type GetJobResponse {
  GetJobResponse(job: JobDetailResponse)
}

pub fn list_response_decoder() -> decode.Decoder(ListJobsResponse) {
  use summary <- decode.field("summary", summary_decoder())
  use page <- decode.field(
    "page",
    pagination_model.page_decoder("jobs", job_decoder()),
  )
  decode.success(ListJobsResponse(summary:, page: page))
}

pub fn encode_list_response(response: ListJobsResponse) -> json.Json {
  json.object([
    #("summary", encode_summary(response.summary)),
    #("page", pagination_model.encode_page(response.page, "jobs", encode_job)),
  ])
}

pub fn get_response_decoder() -> decode.Decoder(GetJobResponse) {
  use job <- decode.field("job", job_detail_decoder())
  decode.success(GetJobResponse(job: job))
}

pub fn encode_get_response(response: GetJobResponse) -> json.Json {
  json.object([#("job", encode_job_detail(response.job))])
}

pub fn from_jobs(
  summary summary: job_model.Summary,
  page page: pagination_model.CursorPage(job_model.Job),
  now now: timestamp.Timestamp,
) -> ListJobsResponse {
  ListJobsResponse(
    summary: JobsSummary(
      total_count: summary.total_count,
      pending_count: summary.pending_count,
      running_count: summary.running_count,
      failed_count: summary.failed_count,
      done_count: summary.done_count,
      overdue_count: summary.overdue_count,
    ),
    page: pagination_model.map_page(page, fn(job) { from_job(job, now) }),
  )
}

pub fn empty_summary() -> JobsSummary {
  JobsSummary(
    total_count: 0,
    pending_count: 0,
    running_count: 0,
    failed_count: 0,
    done_count: 0,
    overdue_count: 0,
  )
}

pub fn from_job_detail(
  job: job_model.Job,
  now: timestamp.Timestamp,
) -> GetJobResponse {
  GetJobResponse(job: JobDetailResponse(
    id: job.id,
    request_id: job.request_id,
    periodic_job_id: job.periodic_job_id,
    job_type: job_model.job_type_to_string(job.job_type),
    queue_name: job_model.queue_to_string(job.queue),
    dedupe_key: job.dedupe_key,
    payload: job.payload,
    status: job_model.status_to_string(job.status),
    attempts: job.attempts,
    max_attempts: job.max_attempts,
    timeout_seconds: job.timeout_seconds,
    run_at: job.run_at,
    started_at: job.started_at,
    lease_expires_at: job.lease_expires_at,
    completed_at: job.completed_at,
    timed_out_at: job.timed_out_at,
    last_error: job.last_error,
    created_at: job.created_at,
    updated_at: job.updated_at,
    overdue: is_overdue(job, now),
  ))
}

pub fn from_job(job: job_model.Job, now: timestamp.Timestamp) -> JobResponse {
  JobResponse(
    id: job.id,
    request_id: job.request_id,
    periodic_job_id: job.periodic_job_id,
    job_type: job_model.job_type_to_string(job.job_type),
    queue_name: job_model.queue_to_string(job.queue),
    dedupe_key: job.dedupe_key,
    status: job_model.status_to_string(job.status),
    attempts: job.attempts,
    max_attempts: job.max_attempts,
    timeout_seconds: job.timeout_seconds,
    run_at: job.run_at,
    started_at: job.started_at,
    lease_expires_at: job.lease_expires_at,
    completed_at: job.completed_at,
    timed_out_at: job.timed_out_at,
    last_error: job.last_error,
    created_at: job.created_at,
    updated_at: job.updated_at,
    overdue: is_overdue(job, now),
  )
}

fn is_overdue(job: job_model.Job, now: timestamp.Timestamp) -> Bool {
  case job.status {
    job_model.Pending -> is_before(job.run_at, now)
    job_model.Running | job_model.Done | job_model.Failed -> False
  }
}

fn is_before(a: timestamp.Timestamp, b: timestamp.Timestamp) -> Bool {
  let #(a_seconds, a_nanos) = timestamp.to_unix_seconds_and_nanoseconds(a)
  let #(b_seconds, b_nanos) = timestamp.to_unix_seconds_and_nanoseconds(b)

  case a_seconds < b_seconds {
    True -> True
    False ->
      case a_seconds > b_seconds {
        True -> False
        False -> a_nanos < b_nanos
      }
  }
}

fn job_decoder() -> decode.Decoder(JobResponse) {
  use id <- decode.field("id", uuid_helpers.decoder())
  use request_id <- decode.field(
    "requestId",
    decode.optional(uuid_helpers.decoder()),
  )
  use periodic_job_id <- decode.field(
    "periodicJobId",
    decode.optional(uuid_helpers.decoder()),
  )
  use job_type <- decode.field("jobType", decode.string)
  use queue_name <- decode.field("queueName", decode.string)
  use dedupe_key <- decode.field("dedupeKey", decode.optional(decode.string))
  use status <- decode.field("status", decode.string)
  use attempts <- decode.field("attempts", decode.int)
  use max_attempts <- decode.field("maxAttempts", decode.int)
  use timeout_seconds <- decode.field("timeoutSeconds", decode.int)
  use run_at <- decode.field("runAt", timestamp_helpers.decoder())
  use started_at <- decode.field(
    "startedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use lease_expires_at <- decode.field(
    "leaseExpiresAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use completed_at <- decode.field(
    "completedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use timed_out_at <- decode.field(
    "timedOutAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use last_error <- decode.field("lastError", decode.optional(decode.string))
  use created_at <- decode.field("createdAt", timestamp_helpers.decoder())
  use updated_at <- decode.field("updatedAt", timestamp_helpers.decoder())
  use overdue <- decode.field("overdue", decode.bool)

  decode.success(JobResponse(
    id: id,
    request_id: request_id,
    periodic_job_id: periodic_job_id,
    job_type: job_type,
    queue_name: queue_name,
    dedupe_key: dedupe_key,
    status: status,
    attempts: attempts,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    run_at: run_at,
    started_at: started_at,
    lease_expires_at: lease_expires_at,
    completed_at: completed_at,
    timed_out_at: timed_out_at,
    last_error: last_error,
    created_at: created_at,
    updated_at: updated_at,
    overdue: overdue,
  ))
}

fn job_detail_decoder() -> decode.Decoder(JobDetailResponse) {
  use id <- decode.field("id", uuid_helpers.decoder())
  use request_id <- decode.field(
    "requestId",
    decode.optional(uuid_helpers.decoder()),
  )
  use periodic_job_id <- decode.field(
    "periodicJobId",
    decode.optional(uuid_helpers.decoder()),
  )
  use job_type <- decode.field("jobType", decode.string)
  use queue_name <- decode.field("queueName", decode.string)
  use dedupe_key <- decode.field("dedupeKey", decode.optional(decode.string))
  use payload <- decode.field("payload", decode.optional(decode.string))
  use status <- decode.field("status", decode.string)
  use attempts <- decode.field("attempts", decode.int)
  use max_attempts <- decode.field("maxAttempts", decode.int)
  use timeout_seconds <- decode.field("timeoutSeconds", decode.int)
  use run_at <- decode.field("runAt", timestamp_helpers.decoder())
  use started_at <- decode.field(
    "startedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use lease_expires_at <- decode.field(
    "leaseExpiresAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use completed_at <- decode.field(
    "completedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use timed_out_at <- decode.field(
    "timedOutAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use last_error <- decode.field("lastError", decode.optional(decode.string))
  use created_at <- decode.field("createdAt", timestamp_helpers.decoder())
  use updated_at <- decode.field("updatedAt", timestamp_helpers.decoder())
  use overdue <- decode.field("overdue", decode.bool)

  decode.success(JobDetailResponse(
    id: id,
    request_id: request_id,
    periodic_job_id: periodic_job_id,
    job_type: job_type,
    queue_name: queue_name,
    dedupe_key: dedupe_key,
    payload: payload,
    status: status,
    attempts: attempts,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    run_at: run_at,
    started_at: started_at,
    lease_expires_at: lease_expires_at,
    completed_at: completed_at,
    timed_out_at: timed_out_at,
    last_error: last_error,
    created_at: created_at,
    updated_at: updated_at,
    overdue: overdue,
  ))
}

fn encode_job(job: JobResponse) -> json.Json {
  json.object([
    #("id", json.string(uuid.to_string(job.id))),
    #("requestId", json.nullable(job.request_id, encode_uuid)),
    #("periodicJobId", json.nullable(job.periodic_job_id, encode_uuid)),
    #("jobType", json.string(job.job_type)),
    #("queueName", json.string(job.queue_name)),
    #("dedupeKey", json.nullable(job.dedupe_key, json.string)),
    #("status", json.string(job.status)),
    #("attempts", json.int(job.attempts)),
    #("maxAttempts", json.int(job.max_attempts)),
    #("timeoutSeconds", json.int(job.timeout_seconds)),
    #("runAt", timestamp_helpers.encode(job.run_at)),
    #("startedAt", json.nullable(job.started_at, timestamp_helpers.encode)),
    #(
      "leaseExpiresAt",
      json.nullable(job.lease_expires_at, timestamp_helpers.encode),
    ),
    #("completedAt", json.nullable(job.completed_at, timestamp_helpers.encode)),
    #("timedOutAt", json.nullable(job.timed_out_at, timestamp_helpers.encode)),
    #("lastError", json.nullable(job.last_error, json.string)),
    #("createdAt", timestamp_helpers.encode(job.created_at)),
    #("updatedAt", timestamp_helpers.encode(job.updated_at)),
    #("overdue", json.bool(job.overdue)),
  ])
}

fn encode_job_detail(job: JobDetailResponse) -> json.Json {
  json.object([
    #("id", encode_uuid(job.id)),
    #("requestId", json.nullable(job.request_id, encode_uuid)),
    #("periodicJobId", json.nullable(job.periodic_job_id, encode_uuid)),
    #("jobType", json.string(job.job_type)),
    #("queueName", json.string(job.queue_name)),
    #("dedupeKey", json.nullable(job.dedupe_key, json.string)),
    #("payload", json.nullable(job.payload, json.string)),
    #("status", json.string(job.status)),
    #("attempts", json.int(job.attempts)),
    #("maxAttempts", json.int(job.max_attempts)),
    #("timeoutSeconds", json.int(job.timeout_seconds)),
    #("runAt", timestamp_helpers.encode(job.run_at)),
    #("startedAt", json.nullable(job.started_at, timestamp_helpers.encode)),
    #(
      "leaseExpiresAt",
      json.nullable(job.lease_expires_at, timestamp_helpers.encode),
    ),
    #("completedAt", json.nullable(job.completed_at, timestamp_helpers.encode)),
    #("timedOutAt", json.nullable(job.timed_out_at, timestamp_helpers.encode)),
    #("lastError", json.nullable(job.last_error, json.string)),
    #("createdAt", timestamp_helpers.encode(job.created_at)),
    #("updatedAt", timestamp_helpers.encode(job.updated_at)),
    #("overdue", json.bool(job.overdue)),
  ])
}

fn summary_decoder() -> decode.Decoder(JobsSummary) {
  use total_count <- decode.field("totalCount", decode.int)
  use pending_count <- decode.field("pendingCount", decode.int)
  use running_count <- decode.field("runningCount", decode.int)
  use failed_count <- decode.field("failedCount", decode.int)
  use done_count <- decode.field("doneCount", decode.int)
  use overdue_count <- decode.field("overdueCount", decode.int)

  decode.success(JobsSummary(
    total_count: total_count,
    pending_count: pending_count,
    running_count: running_count,
    failed_count: failed_count,
    done_count: done_count,
    overdue_count: overdue_count,
  ))
}

fn encode_summary(summary: JobsSummary) -> json.Json {
  json.object([
    #("totalCount", json.int(summary.total_count)),
    #("pendingCount", json.int(summary.pending_count)),
    #("runningCount", json.int(summary.running_count)),
    #("failedCount", json.int(summary.failed_count)),
    #("doneCount", json.int(summary.done_count)),
    #("overdueCount", json.int(summary.overdue_count)),
  ])
}

fn status_filter_decoder() -> decode.Decoder(StatusFilter) {
  decode.then(decode.string, fn(value) {
    case value {
      "all" -> decode.success(AllStatuses)
      "pending" -> decode.success(PendingStatus)
      "running" -> decode.success(RunningStatus)
      "failed" -> decode.success(FailedStatus)
      "done" -> decode.success(DoneStatus)
      _ -> decode.failure(AllStatuses, "StatusFilter")
    }
  })
}

fn encode_status_filter(filter: StatusFilter) -> json.Json {
  case filter {
    AllStatuses -> json.string("all")
    PendingStatus -> json.string("pending")
    RunningStatus -> json.string("running")
    FailedStatus -> json.string("failed")
    DoneStatus -> json.string("done")
  }
}

fn encode_uuid(id: uuid.Uuid) -> json.Json {
  json.string(uuid.to_string(id))
}
