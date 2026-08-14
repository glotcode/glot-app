import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/effect/effect as job_effect
import glot_backend/job/effect/periodic/algebra as periodic_job_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/periodic_job/periodic_job_model
import youid/uuid

pub fn list_periodic_jobs() -> program_types.Program(
  List(periodic_job_model.PeriodicJob),
) {
  program.perform_db(list_periodic_jobs_effect(program.succeed))
}

pub fn get_next_periodic_job(
  now: Timestamp,
) -> program_types.Program(option.Option(periodic_job_model.PeriodicJob)) {
  program.perform_db(get_next_periodic_job_effect(now, program.succeed))
}

pub fn get_periodic_job_by_id(
  id: uuid.Uuid,
) -> program_types.Program(option.Option(periodic_job_model.PeriodicJob)) {
  program.perform_db(get_periodic_job_by_id_effect(id, program.succeed))
}

pub fn create_periodic_job(
  periodic_job periodic_job: periodic_job_model.PeriodicJob,
) -> program_types.Program(Nil) {
  program.perform_db(
    create_periodic_job_effect(periodic_job, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn update_periodic_job(
  periodic_job periodic_job: periodic_job_model.PeriodicJob,
) -> program_types.Program(Nil) {
  program.perform_db(
    update_periodic_job_effect(periodic_job, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn get_next_periodic_job_tx(
  now: Timestamp,
) -> program_types.TransactionProgram(
  option.Option(periodic_job_model.PeriodicJob),
) {
  transaction_program.perform(get_next_periodic_job_effect(
    now,
    transaction_program.succeed,
  ))
}

pub fn create_periodic_job_tx(
  periodic_job periodic_job: periodic_job_model.PeriodicJob,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    create_periodic_job_effect(
      periodic_job,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

pub fn update_periodic_job_tx(
  periodic_job periodic_job: periodic_job_model.PeriodicJob,
) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    update_periodic_job_effect(
      periodic_job,
      transaction_program.from_mapped_result(
        _,
        map_error: error.database_command_error,
      ),
    ),
  )
}

fn list_periodic_jobs_effect(
  next: fn(List(periodic_job_model.PeriodicJob)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.periodic(periodic_job_algebra.ListPeriodicJobs(next: next))
}

fn get_next_periodic_job_effect(
  now: Timestamp,
  next: fn(option.Option(periodic_job_model.PeriodicJob)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.periodic(periodic_job_algebra.GetNextPeriodicJob(
    now: now,
    next: next,
  ))
}

fn get_periodic_job_by_id_effect(
  id: uuid.Uuid,
  next: fn(option.Option(periodic_job_model.PeriodicJob)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.periodic(periodic_job_algebra.GetPeriodicJobById(
    id: id,
    next: next,
  ))
}

fn create_periodic_job_effect(
  periodic_job: periodic_job_model.PeriodicJob,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.periodic(periodic_job_algebra.CreatePeriodicJob(periodic_job, next))
}

fn update_periodic_job_effect(
  periodic_job: periodic_job_model.PeriodicJob,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.periodic(periodic_job_algebra.UpdatePeriodicJob(periodic_job, next))
}
