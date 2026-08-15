import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/periodic_job/periodic_job_model
import youid/uuid

pub type PeriodicJobEffect(next) {
  ListPeriodicJobs(next: fn(List(periodic_job_model.PeriodicJob)) -> next)
  GetNextPeriodicJob(
    now: Timestamp,
    next: fn(Option(periodic_job_model.PeriodicJob)) -> next,
  )
  GetPeriodicJobById(
    id: uuid.Uuid,
    next: fn(Option(periodic_job_model.PeriodicJob)) -> next,
  )
  GetPeriodicJobByIdForUpdate(
    id: uuid.Uuid,
    next: fn(Option(periodic_job_model.PeriodicJob)) -> next,
  )
  CreatePeriodicJob(
    periodic_job_model.PeriodicJob,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdatePeriodicJob(
    periodic_job_model.PeriodicJob,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub fn map(
  effect: PeriodicJobEffect(a),
  f: fn(a) -> b,
) -> PeriodicJobEffect(b) {
  case effect {
    ListPeriodicJobs(next:) ->
      ListPeriodicJobs(next: fn(value) { f(next(value)) })
    GetNextPeriodicJob(now:, next:) ->
      GetNextPeriodicJob(now: now, next: fn(value) { f(next(value)) })
    GetPeriodicJobById(id:, next:) ->
      GetPeriodicJobById(id: id, next: fn(value) { f(next(value)) })
    GetPeriodicJobByIdForUpdate(id:, next:) ->
      GetPeriodicJobByIdForUpdate(id: id, next: fn(value) { f(next(value)) })
    CreatePeriodicJob(periodic_job, next) ->
      CreatePeriodicJob(periodic_job, next: fn(value) { f(next(value)) })
    UpdatePeriodicJob(periodic_job, next) ->
      UpdatePeriodicJob(periodic_job, next: fn(value) { f(next(value)) })
  }
}

pub type EffectName {
  ListPeriodicJobsEffectName
  GetNextPeriodicJobEffectName
  GetPeriodicJobByIdEffectName
  GetPeriodicJobByIdForUpdateEffectName
  CreatePeriodicJobEffectName
  UpdatePeriodicJobEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    ListPeriodicJobsEffectName -> "list_periodic_jobs"
    GetNextPeriodicJobEffectName -> "get_next_periodic_job"
    GetPeriodicJobByIdEffectName -> "get_periodic_job_by_id"
    GetPeriodicJobByIdForUpdateEffectName -> "get_periodic_job_by_id_for_update"
    CreatePeriodicJobEffectName -> "create_periodic_job"
    UpdatePeriodicJobEffectName -> "update_periodic_job"
  }
}
