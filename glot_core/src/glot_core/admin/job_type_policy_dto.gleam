import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers
import glot_core/job/job_model

pub type ListJobTypePoliciesResponse {
  ListJobTypePoliciesResponse(policies: List(JobTypePolicyResponse))
}

pub type JobTypePolicyResponse {
  JobTypePolicyResponse(
    job_type: String,
    queue_name: String,
    max_attempts: Int,
    timeout_seconds: Int,
    base_backoff_seconds: Int,
    max_backoff_seconds: Int,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub type UpsertJobTypePolicyRequest {
  UpsertJobTypePolicyRequest(
    job_type: String,
    queue_name: String,
    max_attempts: Int,
    timeout_seconds: Int,
    base_backoff_seconds: Int,
    max_backoff_seconds: Int,
  )
}

pub fn list_response_decoder() -> decode.Decoder(ListJobTypePoliciesResponse) {
  use policies <- decode.field(
    "policies",
    decode.list(policy_response_decoder()),
  )
  decode.success(ListJobTypePoliciesResponse(policies: policies))
}

pub fn encode_list_response(
  response: ListJobTypePoliciesResponse,
) -> json.Json {
  json.object([
    #("policies", json.array(response.policies, encode_policy_response)),
  ])
}

pub fn policy_response_decoder() -> decode.Decoder(JobTypePolicyResponse) {
  use job_type <- decode.field("jobType", decode.string)
  use queue_name <- decode.field("queueName", decode.string)
  use max_attempts <- decode.field("maxAttempts", decode.int)
  use timeout_seconds <- decode.field("timeoutSeconds", decode.int)
  use base_backoff_seconds <- decode.field("baseBackoffSeconds", decode.int)
  use max_backoff_seconds <- decode.field("maxBackoffSeconds", decode.int)
  use created_at <- decode.field("createdAt", timestamp_helpers.decoder())
  use updated_at <- decode.field("updatedAt", timestamp_helpers.decoder())
  decode.success(JobTypePolicyResponse(
    job_type: job_type,
    queue_name: queue_name,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    base_backoff_seconds: base_backoff_seconds,
    max_backoff_seconds: max_backoff_seconds,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

pub fn encode_policy_response(response: JobTypePolicyResponse) -> json.Json {
  json.object([
    #("jobType", json.string(response.job_type)),
    #("queueName", json.string(response.queue_name)),
    #("maxAttempts", json.int(response.max_attempts)),
    #("timeoutSeconds", json.int(response.timeout_seconds)),
    #("baseBackoffSeconds", json.int(response.base_backoff_seconds)),
    #("maxBackoffSeconds", json.int(response.max_backoff_seconds)),
    #("createdAt", timestamp_helpers.encode(response.created_at)),
    #("updatedAt", timestamp_helpers.encode(response.updated_at)),
  ])
}

pub fn request_decoder() -> decode.Decoder(UpsertJobTypePolicyRequest) {
  use job_type <- decode.field("jobType", decode.string)
  use queue_name <- decode.field("queueName", decode.string)
  use max_attempts <- decode.field("maxAttempts", decode.int)
  use timeout_seconds <- decode.field("timeoutSeconds", decode.int)
  use base_backoff_seconds <- decode.field("baseBackoffSeconds", decode.int)
  use max_backoff_seconds <- decode.field("maxBackoffSeconds", decode.int)
  decode.success(UpsertJobTypePolicyRequest(
    job_type: job_type,
    queue_name: queue_name,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    base_backoff_seconds: base_backoff_seconds,
    max_backoff_seconds: max_backoff_seconds,
  ))
}

pub fn encode_request(request: UpsertJobTypePolicyRequest) -> json.Json {
  json.object([
    #("jobType", json.string(request.job_type)),
    #("queueName", json.string(request.queue_name)),
    #("maxAttempts", json.int(request.max_attempts)),
    #("timeoutSeconds", json.int(request.timeout_seconds)),
    #("baseBackoffSeconds", json.int(request.base_backoff_seconds)),
    #("maxBackoffSeconds", json.int(request.max_backoff_seconds)),
  ])
}

pub fn from_job_type_policies(
  policies: List(job_model.JobTypePolicy),
) -> ListJobTypePoliciesResponse {
  ListJobTypePoliciesResponse(policies: list.map(policies, from_job_type_policy))
}

pub fn from_job_type_policy(
  policy: job_model.JobTypePolicy,
) -> JobTypePolicyResponse {
  JobTypePolicyResponse(
    job_type: job_model.job_type_to_string(policy.job_type),
    queue_name: job_model.queue_to_string(policy.queue),
    max_attempts: policy.max_attempts,
    timeout_seconds: policy.timeout_seconds,
    base_backoff_seconds: policy.base_backoff_seconds,
    max_backoff_seconds: policy.max_backoff_seconds,
    created_at: policy.created_at,
    updated_at: policy.updated_at,
  )
}
