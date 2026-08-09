import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/regexp
import gleam/time/timestamp.{type Timestamp}
import glot_core/email/email_address_model
import glot_core/email/email_model
import glot_core/helpers/uuid_helpers
import glot_core/validation_error
import youid/uuid.{type Uuid}

pub type JobType {
  SendEmailJob
  DeleteAccountJob
  CleanApiLogJob
  CleanPageLogJob
  CleanPageviewLogJob
  CleanRunLogJob
  CleanJobLogJob
  CleanJobsJob
  CleanSessionsJob
  CleanVerificationTokensJob
  CleanUserActionsJob
  AggregateMetricsJob
}

pub fn job_type_to_string(job_type: JobType) -> String {
  case job_type {
    SendEmailJob -> "send_email"
    DeleteAccountJob -> "delete_account"
    CleanApiLogJob -> "clean_api_log"
    CleanPageLogJob -> "clean_page_log"
    CleanPageviewLogJob -> "clean_pageview_log"
    CleanRunLogJob -> "clean_run_log"
    CleanJobLogJob -> "clean_job_log"
    CleanJobsJob -> "clean_jobs"
    CleanSessionsJob -> "clean_sessions"
    CleanVerificationTokensJob -> "clean_login_tokens"
    CleanUserActionsJob -> "clean_user_actions"
    AggregateMetricsJob -> "aggregate_metrics"
  }
}

pub fn job_type_from_string(
  value: String,
) -> Result(JobType, validation_error.ValidationError) {
  case value {
    "send_email" -> Ok(SendEmailJob)
    "delete_account" -> Ok(DeleteAccountJob)
    "clean_api_log" -> Ok(CleanApiLogJob)
    "clean_page_log" -> Ok(CleanPageLogJob)
    "clean_pageview_log" -> Ok(CleanPageviewLogJob)
    "clean_run_log" -> Ok(CleanRunLogJob)
    "clean_job_log" -> Ok(CleanJobLogJob)
    "clean_jobs" -> Ok(CleanJobsJob)
    "clean_sessions" -> Ok(CleanSessionsJob)
    "clean_login_tokens" -> Ok(CleanVerificationTokensJob)
    "clean_user_actions" -> Ok(CleanUserActionsJob)
    "aggregate_metrics" -> Ok(AggregateMetricsJob)
    _ -> Error(validation_error.InvalidJobType(value))
  }
}

pub type Status {
  Pending
  Running
  Done
  Failed
}

pub type JobTypePolicy {
  JobTypePolicy(
    job_type: JobType,
    max_attempts: Int,
    timeout_seconds: Int,
    base_backoff_seconds: Int,
    max_backoff_seconds: Int,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub type ListJobsFilter {
  ListJobsFilter(
    statuses: List(Status),
    job_type: Option(String),
    periodic_job_id: Option(Uuid),
  )
}

pub fn new_list_filter() -> ListJobsFilter {
  ListJobsFilter(
    statuses: [],
    job_type: option.None,
    periodic_job_id: option.None,
  )
}

pub fn with_statuses(
  filter: ListJobsFilter,
  statuses: List(Status),
) -> ListJobsFilter {
  ListJobsFilter(..filter, statuses: statuses)
}

pub fn with_job_type(
  filter: ListJobsFilter,
  job_type: Option(String),
) -> ListJobsFilter {
  ListJobsFilter(..filter, job_type: job_type)
}

pub fn with_periodic_job_id(
  filter: ListJobsFilter,
  periodic_job_id: Option(Uuid),
) -> ListJobsFilter {
  ListJobsFilter(..filter, periodic_job_id: periodic_job_id)
}

pub type Summary {
  Summary(
    total_count: Int,
    pending_count: Int,
    running_count: Int,
    failed_count: Int,
    done_count: Int,
    overdue_count: Int,
  )
}

pub fn status_to_string(status: Status) -> String {
  case status {
    Pending -> "pending"
    Running -> "running"
    Done -> "done"
    Failed -> "failed"
  }
}

pub fn status_from_string(value: String) -> Result(Status, String) {
  case value {
    "pending" -> Ok(Pending)
    "running" -> Ok(Running)
    "done" -> Ok(Done)
    "failed" -> Ok(Failed)
    _ -> Error("Invalid job status: " <> value)
  }
}

pub type Job {
  Job(
    id: Uuid,
    request_id: Option(Uuid),
    periodic_job_id: Option(Uuid),
    job_type: JobType,
    payload: Option(String),
    status: Status,
    attempts: Int,
    max_attempts: Int,
    timeout_seconds: Int,
    base_backoff_seconds: Int,
    max_backoff_seconds: Int,
    run_at: Timestamp,
    started_at: Option(Timestamp),
    lease_expires_at: Option(Timestamp),
    completed_at: Option(Timestamp),
    timed_out_at: Option(Timestamp),
    last_error: Option(String),
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub type DeleteAccountJobPayload {
  DeleteAccountJobPayload(
    account_id: Uuid,
    email: email_address_model.EmailAddress,
  )
}

fn new(
  id: Uuid,
  request_id: Option(Uuid),
  periodic_job_id: Option(Uuid),
  job_type: JobType,
  now: Timestamp,
  payload: Option(String),
  policy: JobTypePolicy,
) -> Job {
  Job(
    id: id,
    request_id: request_id,
    periodic_job_id: periodic_job_id,
    job_type: job_type,
    payload: payload,
    status: Pending,
    attempts: 0,
    max_attempts: policy.max_attempts,
    timeout_seconds: policy.timeout_seconds,
    base_backoff_seconds: policy.base_backoff_seconds,
    max_backoff_seconds: policy.max_backoff_seconds,
    run_at: now,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    timed_out_at: option.None,
    last_error: option.None,
    created_at: now,
    updated_at: now,
  )
}

pub fn send_email_job(
  id: Uuid,
  request_id: Option(Uuid),
  now: Timestamp,
  email: email_model.Email,
  policy: JobTypePolicy,
) -> Job {
  new(
    id,
    request_id,
    option.None,
    SendEmailJob,
    now,
    option.Some(
      email
      |> email_model.encode
      |> json.to_string,
    ),
    policy,
  )
}

pub fn delete_account_job(
  id: Uuid,
  request_id: Option(Uuid),
  now: Timestamp,
  run_at: Timestamp,
  account_id: Uuid,
  email: email_address_model.EmailAddress,
  policy: JobTypePolicy,
) -> Job {
  let payload =
    DeleteAccountJobPayload(account_id:, email:)
    |> encode_delete_account_job_payload
    |> json.to_string

  Job(
    ..new(
      id,
      request_id,
      option.None,
      DeleteAccountJob,
      now,
      option.Some(payload),
      policy,
    ),
    run_at: run_at,
  )
}

pub fn encode_delete_account_job_payload(
  payload: DeleteAccountJobPayload,
) -> json.Json {
  json.object([
    #("accountId", json.string(uuid.to_string(payload.account_id))),
    #("email", email_address_model.encode(payload.email)),
  ])
}

pub fn delete_account_job_payload_decoder() -> decode.Decoder(
  DeleteAccountJobPayload,
) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  use account_id <- decode.field("accountId", uuid_helpers.decoder())
  use email <- decode.field("email", email_address_model.decoder(is_email))
  decode.success(DeleteAccountJobPayload(account_id:, email:))
}

pub fn periodic_job_execution(
  id: Uuid,
  now: Timestamp,
  periodic_job_id: Uuid,
  job_type: JobType,
  payload: Option(String),
  policy: JobTypePolicy,
) -> Job {
  new(
    id,
    option.None,
    option.Some(periodic_job_id),
    job_type,
    now,
    payload,
    policy,
  )
}

pub fn done(job: Job, now: Timestamp) -> Job {
  Job(
    ..job,
    status: Done,
    lease_expires_at: option.None,
    completed_at: option.Some(now),
    last_error: option.None,
    updated_at: now,
  )
}

pub fn start(job: Job, now: Timestamp) -> Job {
  Job(
    ..job,
    status: Running,
    attempts: job.attempts + 1,
    started_at: option.Some(now),
    lease_expires_at: option.Some(add_seconds(now, job.timeout_seconds)),
    updated_at: now,
  )
}

pub fn reschedule(
  job: Job,
  run_at: Timestamp,
  last_error: Option(String),
  updated_at: Timestamp,
) -> Job {
  let status = case job.attempts >= job.max_attempts {
    True -> Failed
    False -> Pending
  }

  Job(
    ..job,
    status: status,
    run_at: run_at,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    last_error: last_error,
    updated_at: updated_at,
  )
}

pub fn fail(
  job: Job,
  last_error: Option(String),
  updated_at: Timestamp,
) -> Job {
  Job(
    ..job,
    status: Failed,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    last_error: last_error,
    updated_at: updated_at,
  )
}

pub fn timed_out(job: Job, run_at: Timestamp, updated_at: Timestamp) -> Job {
  let status = case job.attempts >= job.max_attempts {
    True -> Failed
    False -> Pending
  }

  Job(
    ..job,
    status: status,
    run_at: run_at,
    started_at: option.None,
    lease_expires_at: option.None,
    completed_at: option.None,
    timed_out_at: option.Some(updated_at),
    last_error: option.Some("timeout_exceeded"),
    updated_at: updated_at,
  )
}

fn add_seconds(ts: Timestamp, seconds_to_add: Int) -> Timestamp {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  timestamp.from_unix_seconds_and_nanoseconds(seconds + seconds_to_add, nanos)
}

pub type Outcome {
  NoJobs
  JobProcessed
}
