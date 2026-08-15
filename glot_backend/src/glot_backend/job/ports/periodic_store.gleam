import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/periodic_job/periodic_job_model
import youid/uuid.{type Uuid}

pub type PeriodicStore {
  PeriodicStore(
    list_periodic_jobs: fn() ->
      Result(List(periodic_job_model.PeriodicJob), db_error.DbQueryError),
    get_next_periodic_job: fn(Timestamp) ->
      Result(
        option.Option(periodic_job_model.PeriodicJob),
        db_error.DbQueryError,
      ),
    get_periodic_job_by_id: fn(Uuid) ->
      Result(
        option.Option(periodic_job_model.PeriodicJob),
        db_error.DbQueryError,
      ),
    get_periodic_job_by_id_for_update: fn(Uuid) ->
      Result(
        option.Option(periodic_job_model.PeriodicJob),
        db_error.DbQueryError,
      ),
    create_periodic_job: fn(periodic_job_model.PeriodicJob) ->
      Result(Nil, db_error.DbCommandError),
    update_periodic_job: fn(periodic_job_model.PeriodicJob) ->
      Result(Nil, db_error.DbCommandError),
  )
}
