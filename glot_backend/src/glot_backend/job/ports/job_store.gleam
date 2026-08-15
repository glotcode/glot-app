import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/job/job_model
import glot_core/pagination_model.{type CursorPagination}
import youid/uuid.{type Uuid}

pub type JobStore {
  JobStore(
    list_jobs: fn(job_model.ListJobsFilter, CursorPagination) ->
      Result(List(job_model.Job), db_error.DbQueryError),
    summarize_jobs: fn(job_model.ListJobsFilter, Timestamp) ->
      Result(job_model.Summary, db_error.DbQueryError),
    get_next_job: fn(job_model.Queue, Timestamp, job_model.Status) ->
      Result(option.Option(job_model.Job), db_error.DbQueryError),
    get_expired_running_job: fn(job_model.Queue, Timestamp, job_model.Status) ->
      Result(option.Option(job_model.Job), db_error.DbQueryError),
    get_job_by_id: fn(Uuid) ->
      Result(option.Option(job_model.Job), db_error.DbQueryError),
    create_job: fn(job_model.Job) -> Result(Nil, db_error.DbCommandError),
    update_job: fn(job_model.Job) -> Result(Nil, db_error.DbCommandError),
    claim_queue_slot: fn(job_model.Queue, Uuid, Timestamp) ->
      Result(Bool, db_error.DbQueryError),
    release_queue_slot: fn(Uuid, Timestamp) ->
      Result(Nil, db_error.DbCommandError),
    delete_job: fn(Uuid) -> Result(Nil, db_error.DbCommandError),
    delete_before: fn(Timestamp, List(job_model.Status)) ->
      Result(Nil, db_error.DbCommandError),
  )
}
