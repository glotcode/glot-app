import gleam/option
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import glot_backend/sql
import glot_backend/system/effect/error/db_error
import glot_core/helpers/uuid_helpers
import glot_core/job/job_model
import glot_core/validation_error

pub fn from_next(
  row: sql.GetNextJob,
) -> Result(job_model.Job, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    request_id: row.request_id,
    periodic_job_id: row.periodic_job_id,
    job_type_name: row.job_type,
    queue_name: row.queue_name,
    dedupe_key: row.dedupe_key,
    payload: row.payload,
    status_name: row.status,
    attempts: row.attempts,
    max_attempts: row.max_attempts,
    timeout_seconds: row.timeout_seconds,
    base_backoff_seconds: row.base_backoff_seconds,
    max_backoff_seconds: row.max_backoff_seconds,
    run_at: row.run_at,
    started_at: row.started_at,
    lease_expires_at: row.lease_expires_at,
    completed_at: row.completed_at,
    timed_out_at: row.timed_out_at,
    last_error: row.last_error,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_expired_running(
  row: sql.GetExpiredRunningJob,
) -> Result(job_model.Job, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    request_id: row.request_id,
    periodic_job_id: row.periodic_job_id,
    job_type_name: row.job_type,
    queue_name: row.queue_name,
    dedupe_key: row.dedupe_key,
    payload: row.payload,
    status_name: row.status,
    attempts: row.attempts,
    max_attempts: row.max_attempts,
    timeout_seconds: row.timeout_seconds,
    base_backoff_seconds: row.base_backoff_seconds,
    max_backoff_seconds: row.max_backoff_seconds,
    run_at: row.run_at,
    started_at: row.started_at,
    lease_expires_at: row.lease_expires_at,
    completed_at: row.completed_at,
    timed_out_at: row.timed_out_at,
    last_error: row.last_error,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_list_after(
  row: sql.ListJobsAfter,
) -> Result(job_model.Job, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    request_id: row.request_id,
    periodic_job_id: row.periodic_job_id,
    job_type_name: row.job_type,
    queue_name: row.queue_name,
    dedupe_key: row.dedupe_key,
    payload: row.payload,
    status_name: row.status,
    attempts: row.attempts,
    max_attempts: row.max_attempts,
    timeout_seconds: row.timeout_seconds,
    base_backoff_seconds: row.base_backoff_seconds,
    max_backoff_seconds: row.max_backoff_seconds,
    run_at: row.run_at,
    started_at: row.started_at,
    lease_expires_at: row.lease_expires_at,
    completed_at: row.completed_at,
    timed_out_at: row.timed_out_at,
    last_error: row.last_error,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_list_before(
  row: sql.ListJobsBefore,
) -> Result(job_model.Job, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    request_id: row.request_id,
    periodic_job_id: row.periodic_job_id,
    job_type_name: row.job_type,
    queue_name: row.queue_name,
    dedupe_key: row.dedupe_key,
    payload: row.payload,
    status_name: row.status,
    attempts: row.attempts,
    max_attempts: row.max_attempts,
    timeout_seconds: row.timeout_seconds,
    base_backoff_seconds: row.base_backoff_seconds,
    max_backoff_seconds: row.max_backoff_seconds,
    run_at: row.run_at,
    started_at: row.started_at,
    lease_expires_at: row.lease_expires_at,
    completed_at: row.completed_at,
    timed_out_at: row.timed_out_at,
    last_error: row.last_error,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

pub fn from_id(
  row: sql.GetJobById,
) -> Result(job_model.Job, db_error.DbQueryError) {
  from_fields(
    id: row.id,
    request_id: row.request_id,
    periodic_job_id: row.periodic_job_id,
    job_type_name: row.job_type,
    queue_name: row.queue_name,
    dedupe_key: row.dedupe_key,
    payload: row.payload,
    status_name: row.status,
    attempts: row.attempts,
    max_attempts: row.max_attempts,
    timeout_seconds: row.timeout_seconds,
    base_backoff_seconds: row.base_backoff_seconds,
    max_backoff_seconds: row.max_backoff_seconds,
    run_at: row.run_at,
    started_at: row.started_at,
    lease_expires_at: row.lease_expires_at,
    completed_at: row.completed_at,
    timed_out_at: row.timed_out_at,
    last_error: row.last_error,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn from_fields(
  id id: BitArray,
  request_id request_id: option.Option(BitArray),
  periodic_job_id periodic_job_id: option.Option(BitArray),
  job_type_name job_type_name: String,
  queue_name queue_name: String,
  dedupe_key dedupe_key: option.Option(String),
  payload payload: option.Option(String),
  status_name status_name: String,
  attempts attempts: Int,
  max_attempts max_attempts: Int,
  timeout_seconds timeout_seconds: Int,
  base_backoff_seconds base_backoff_seconds: Int,
  max_backoff_seconds max_backoff_seconds: Int,
  run_at run_at: Timestamp,
  started_at started_at: option.Option(Timestamp),
  lease_expires_at lease_expires_at: option.Option(Timestamp),
  completed_at completed_at: option.Option(Timestamp),
  timed_out_at timed_out_at: option.Option(Timestamp),
  last_error last_error: option.Option(String),
  created_at created_at: Timestamp,
  updated_at updated_at: Timestamp,
) -> Result(job_model.Job, db_error.DbQueryError) {
  use status <- result.try(
    job_model.status_from_string(status_name)
    |> result.map_error(db_error.DbQueryError),
  )
  use job_type <- result.try(
    job_model.job_type_from_string(job_type_name)
    |> result.map_error(validation_error.to_string)
    |> result.map_error(db_error.DbQueryError),
  )
  use queue <- result.try(
    job_model.queue_from_string(queue_name)
    |> result.map_error(db_error.DbQueryError),
  )

  Ok(job_model.Job(
    id: uuid_helpers.from_bit_array(id),
    request_id: request_id |> option.map(uuid_helpers.from_bit_array),
    periodic_job_id: periodic_job_id |> option.map(uuid_helpers.from_bit_array),
    job_type: job_type,
    queue: queue,
    dedupe_key: dedupe_key,
    payload: payload,
    status: status,
    attempts: attempts,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    base_backoff_seconds: base_backoff_seconds,
    max_backoff_seconds: max_backoff_seconds,
    run_at: run_at,
    started_at: started_at,
    lease_expires_at: lease_expires_at,
    completed_at: completed_at,
    timed_out_at: timed_out_at,
    last_error: last_error,
    created_at: created_at,
    updated_at: updated_at,
  ))
}
