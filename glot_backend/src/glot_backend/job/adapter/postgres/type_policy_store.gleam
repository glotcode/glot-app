import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/ports/type_policy_store
import glot_backend/sql
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/error/db_error
import glot_core/job/job_model
import glot_core/validation_error

pub fn new(db: db_helpers.Db) -> type_policy_store.TypePolicyStore {
  type_policy_store.TypePolicyStore(
    list_job_type_policies: fn() { list_job_type_policies(db) },
    get_job_type_policy_by_job_type: fn(job_type) {
      get_job_type_policy_by_job_type(db, job_type)
    },
    upsert_job_type_policy: fn(policy, now) {
      upsert_job_type_policy(db, policy, now)
    },
  )
}

pub fn list_job_type_policies(
  db: db_helpers.Db,
) -> Result(List(job_model.JobTypePolicy), db_error.DbQueryError) {
  use returned <- result.try(
    db_helpers.query(db, sql.list_job_type_policies(), fn(err) {
      db_error.DbQueryError(string.inspect(err))
    }),
  )

  returned.rows
  |> list.map(job_type_policy_from_list_row)
  |> result.all
}

pub fn get_job_type_policy_by_job_type(
  db: db_helpers.Db,
  job_type: job_model.JobType,
) -> Result(option.Option(job_model.JobTypePolicy), db_error.DbQueryError) {
  use returned <- result.try(
    db_helpers.query(
      db,
      sql.get_job_type_policy_by_job_type(
        job_type: job_model.job_type_to_string(job_type),
      ),
      fn(err) { db_error.DbQueryError(string.inspect(err)) },
    ),
  )

  case returned.rows {
    [] -> Ok(option.None)
    [row] -> job_type_policy_from_get_row(row) |> result.map(option.Some)
    _ ->
      Error(db_error.DbQueryError("Expected at most one job type policy row"))
  }
}

pub fn upsert_job_type_policy(
  db: db_helpers.Db,
  policy: job_model.JobTypePolicy,
  now: Timestamp,
) -> Result(Nil, db_error.DbCommandError) {
  db_helpers.execute(
    db,
    sql.upsert_job_type_policy(
      job_type: job_model.job_type_to_string(policy.job_type),
      queue_name: job_model.queue_to_string(policy.queue),
      max_attempts: policy.max_attempts,
      timeout_seconds: policy.timeout_seconds,
      base_backoff_seconds: policy.base_backoff_seconds,
      max_backoff_seconds: policy.max_backoff_seconds,
      created_at: now,
    ),
    fn(err) { db_error.DbCommandError(string.inspect(err)) },
  )
  |> result.map(fn(_) { Nil })
}

fn job_type_policy_from_row(
  job_type: String,
  queue_name: String,
  max_attempts: Int,
  timeout_seconds: Int,
  base_backoff_seconds: Int,
  max_backoff_seconds: Int,
  created_at: Timestamp,
  updated_at: Timestamp,
) -> Result(job_model.JobTypePolicy, db_error.DbQueryError) {
  use job_type <- result.try(
    job_model.job_type_from_string(job_type)
    |> result.map_error(validation_error.to_string)
    |> result.map_error(db_error.DbQueryError),
  )
  use queue <- result.try(
    job_model.queue_from_string(queue_name)
    |> result.map_error(db_error.DbQueryError),
  )

  Ok(job_model.JobTypePolicy(
    job_type: job_type,
    queue: queue,
    max_attempts: max_attempts,
    timeout_seconds: timeout_seconds,
    base_backoff_seconds: base_backoff_seconds,
    max_backoff_seconds: max_backoff_seconds,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

fn job_type_policy_from_list_row(
  row: sql.ListJobTypePolicies,
) -> Result(job_model.JobTypePolicy, db_error.DbQueryError) {
  job_type_policy_from_row(
    row.job_type,
    row.queue_name,
    row.max_attempts,
    row.timeout_seconds,
    row.base_backoff_seconds,
    row.max_backoff_seconds,
    row.created_at,
    row.updated_at,
  )
}

fn job_type_policy_from_get_row(
  row: sql.GetJobTypePolicyByJobType,
) -> Result(job_model.JobTypePolicy, db_error.DbQueryError) {
  job_type_policy_from_row(
    row.job_type,
    row.queue_name,
    row.max_attempts,
    row.timeout_seconds,
    row.base_backoff_seconds,
    row.max_backoff_seconds,
    row.created_at,
    row.updated_at,
  )
}
