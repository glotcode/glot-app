import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/effect/effect as job_effect
import glot_backend/job/effect/job/algebra as job_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/job/job_model
import glot_core/pagination_model.{type CursorPagination}
import youid/uuid.{type Uuid}

pub fn get_next_job(
  queue: job_model.Queue,
  now: Timestamp,
  pending_status: job_model.Status,
) -> program_types.Program(option.Option(job_model.Job)) {
  program.perform_db(get_next_job_effect(
    queue,
    now,
    pending_status,
    program.succeed,
  ))
}

pub fn get_expired_running_job(
  queue: job_model.Queue,
  now: Timestamp,
  running_status: job_model.Status,
) -> program_types.Program(option.Option(job_model.Job)) {
  program.perform_db(get_expired_running_job_effect(
    queue,
    now,
    running_status,
    program.succeed,
  ))
}

pub fn list_jobs(
  filter filter: job_model.ListJobsFilter,
  pagination pagination: CursorPagination,
) -> program_types.Program(List(job_model.Job)) {
  program.perform_db(list_jobs_effect(filter, pagination, program.succeed))
}

pub fn summarize_jobs(
  filter filter: job_model.ListJobsFilter,
  now now: Timestamp,
) -> program_types.Program(job_model.Summary) {
  program.perform_db(summarize_jobs_effect(filter, now, program.succeed))
}

pub fn create_job(job j: job_model.Job) -> program_types.Program(Nil) {
  program.perform_db(
    create_job_effect(j, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn get_job_by_id(
  id id: Uuid,
) -> program_types.Program(option.Option(job_model.Job)) {
  program.perform_db(get_job_by_id_effect(id, program.succeed))
}

pub fn update_job(job j: job_model.Job) -> program_types.Program(Nil) {
  program.perform_db(
    update_job_effect(j, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_job(id id: Uuid) -> program_types.Program(Nil) {
  program.perform_db(
    delete_job_effect(id, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_before(
  before: Timestamp,
  statuses: List(job_model.Status),
) -> program_types.Program(Nil) {
  program.perform_db(
    delete_before_effect(before, statuses, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn get_next_job_tx(
  queue: job_model.Queue,
  now: Timestamp,
  pending_status: job_model.Status,
) -> program_types.TransactionProgram(option.Option(job_model.Job)) {
  transaction_program.perform(get_next_job_effect(
    queue,
    now,
    pending_status,
    transaction_program.succeed,
  ))
}

pub fn get_expired_running_job_tx(
  queue: job_model.Queue,
  now: Timestamp,
  running_status: job_model.Status,
) -> program_types.TransactionProgram(option.Option(job_model.Job)) {
  transaction_program.perform(get_expired_running_job_effect(
    queue,
    now,
    running_status,
    transaction_program.succeed,
  ))
}

pub fn create_job_tx(
  job j: job_model.Job,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    create_job_effect(j, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn get_job_by_id_tx(
  id id: Uuid,
) -> program_types.TransactionProgram(option.Option(job_model.Job)) {
  transaction_program.perform(get_job_by_id_effect(
    id,
    transaction_program.succeed,
  ))
}

pub fn update_job_tx(
  job j: job_model.Job,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    update_job_effect(j, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn claim_queue_slot_tx(
  queue: job_model.Queue,
  job_id: Uuid,
  lease_expires_at: Timestamp,
) -> program_types.TransactionProgram(Bool) {
  transaction_program.perform(
    job_effect.job(job_algebra.ClaimQueueSlot(
      queue: queue,
      job_id: job_id,
      lease_expires_at: lease_expires_at,
      next: transaction_program.succeed,
    )),
  )
}

pub fn release_queue_slot_tx(
  job_id: Uuid,
  lease_expires_at: Timestamp,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    job_effect.job(
      job_algebra.ReleaseQueueSlot(
        job_id: job_id,
        lease_expires_at: lease_expires_at,
        next: transaction_program.from_mapped_result(
          _,
          map_error: error.database_command_error,
        ),
      ),
    ),
  )
}

pub fn delete_job_tx(id id: Uuid) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    delete_job_effect(id, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn delete_before_tx(
  before: Timestamp,
  statuses: List(job_model.Status),
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    delete_before_effect(
      before,
      statuses,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

fn get_next_job_effect(
  queue: job_model.Queue,
  now: Timestamp,
  pending_status: job_model.Status,
  next: fn(option.Option(job_model.Job)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.GetNextJob(
    queue:,
    now:,
    pending_status:,
    next: next,
  ))
}

fn get_expired_running_job_effect(
  queue: job_model.Queue,
  now: Timestamp,
  running_status: job_model.Status,
  next: fn(option.Option(job_model.Job)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.GetExpiredRunningJob(
    queue: queue,
    now: now,
    running_status: running_status,
    next: next,
  ))
}

fn list_jobs_effect(
  filter: job_model.ListJobsFilter,
  pagination: CursorPagination,
  next: fn(List(job_model.Job)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.ListJobs(
    filter: filter,
    pagination: pagination,
    next: next,
  ))
}

fn summarize_jobs_effect(
  filter: job_model.ListJobsFilter,
  now: Timestamp,
  next: fn(job_model.Summary) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.SummarizeJobs(filter: filter, now: now, next: next))
}

fn create_job_effect(
  job: job_model.Job,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.CreateJob(job, next))
}

fn get_job_by_id_effect(
  id: Uuid,
  next: fn(option.Option(job_model.Job)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.GetJobById(id:, next: next))
}

fn update_job_effect(
  job: job_model.Job,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.UpdateJob(job, next))
}

fn delete_job_effect(
  id: Uuid,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.DeleteJob(id, next))
}

fn delete_before_effect(
  before: Timestamp,
  statuses: List(job_model.Status),
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.job(job_algebra.DeleteBefore(
    before: before,
    statuses: statuses,
    next: next,
  ))
}
