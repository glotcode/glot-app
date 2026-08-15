import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/job/job_model
import glot_core/pagination_model.{type CursorPagination}
import youid/uuid.{type Uuid}

pub type JobEffect(next) {
  ListJobs(
    filter: job_model.ListJobsFilter,
    pagination: CursorPagination,
    next: fn(List(job_model.Job)) -> next,
  )
  SummarizeJobs(
    filter: job_model.ListJobsFilter,
    now: Timestamp,
    next: fn(job_model.Summary) -> next,
  )
  GetNextJob(
    queue: job_model.Queue,
    now: Timestamp,
    pending_status: job_model.Status,
    next: fn(Option(job_model.Job)) -> next,
  )
  GetExpiredRunningJob(
    queue: job_model.Queue,
    now: Timestamp,
    running_status: job_model.Status,
    next: fn(Option(job_model.Job)) -> next,
  )
  GetJobById(id: Uuid, next: fn(Option(job_model.Job)) -> next)
  CreateJob(
    job_model.Job,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateJob(
    job_model.Job,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  ClaimQueueSlot(
    queue: job_model.Queue,
    job_id: Uuid,
    lease_expires_at: Timestamp,
    next: fn(Bool) -> next,
  )
  ReleaseQueueSlot(
    job_id: Uuid,
    lease_expires_at: Timestamp,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  DeleteJob(id: Uuid, next: fn(Result(Nil, db_error.DbCommandError)) -> next)
  DeleteBefore(
    before: Timestamp,
    statuses: List(job_model.Status),
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
}

pub fn map(effect: JobEffect(a), f: fn(a) -> b) -> JobEffect(b) {
  case effect {
    ListJobs(filter:, pagination:, next:) ->
      ListJobs(filter: filter, pagination: pagination, next: fn(value) {
        f(next(value))
      })
    SummarizeJobs(filter:, now:, next:) ->
      SummarizeJobs(filter: filter, now: now, next: fn(value) { f(next(value)) })
    GetNextJob(queue:, now:, pending_status:, next:) ->
      GetNextJob(
        queue: queue,
        now: now,
        pending_status: pending_status,
        next: fn(value) { f(next(value)) },
      )
    GetExpiredRunningJob(queue:, now:, running_status:, next:) ->
      GetExpiredRunningJob(
        queue: queue,
        now: now,
        running_status: running_status,
        next: fn(value) { f(next(value)) },
      )
    GetJobById(id:, next:) ->
      GetJobById(id: id, next: fn(value) { f(next(value)) })
    CreateJob(job, next) -> CreateJob(job, next: fn(value) { f(next(value)) })
    UpdateJob(job, next) -> UpdateJob(job, next: fn(value) { f(next(value)) })
    ClaimQueueSlot(queue:, job_id:, lease_expires_at:, next:) ->
      ClaimQueueSlot(
        queue: queue,
        job_id: job_id,
        lease_expires_at: lease_expires_at,
        next: fn(value) { f(next(value)) },
      )
    ReleaseQueueSlot(job_id:, lease_expires_at:, next:) ->
      ReleaseQueueSlot(
        job_id: job_id,
        lease_expires_at: lease_expires_at,
        next: fn(value) { f(next(value)) },
      )
    DeleteJob(id, next) -> DeleteJob(id, next: fn(value) { f(next(value)) })
    DeleteBefore(before:, statuses:, next:) ->
      DeleteBefore(before: before, statuses: statuses, next: fn(value) {
        f(next(value))
      })
  }
}

pub type EffectName {
  ListJobsEffectName
  SummarizeJobsEffectName
  GetNextJobEffectName
  GetExpiredRunningJobEffectName
  GetJobByIdEffectName
  CreateJobEffectName
  UpdateJobEffectName
  ClaimQueueSlotEffectName
  ReleaseQueueSlotEffectName
  DeleteJobEffectName
  DeleteBeforeEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    ListJobsEffectName -> "list_jobs"
    SummarizeJobsEffectName -> "summarize_jobs"
    GetNextJobEffectName -> "get_next_job"
    GetExpiredRunningJobEffectName -> "get_expired_running_job"
    GetJobByIdEffectName -> "get_job_by_id"
    CreateJobEffectName -> "create_job"
    UpdateJobEffectName -> "update_job"
    ClaimQueueSlotEffectName -> "claim_queue_slot"
    ReleaseQueueSlotEffectName -> "release_queue_slot"
    DeleteJobEffectName -> "delete_job"
    DeleteBeforeEffectName -> "delete_before"
  }
}
