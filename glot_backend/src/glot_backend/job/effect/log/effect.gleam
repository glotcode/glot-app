import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/effect/effect as job_effect
import glot_backend/job/effect/log/algebra as job_log_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_core/admin/job_log_dto
import glot_core/job_log_model
import youid/uuid.{type Uuid}

pub fn list(
  request: job_log_dto.ListJobLogsRequest,
) -> program_types.Program(List(job_log_model.JobLog)) {
  program.perform_db(list_effect(request, program.succeed))
}

pub fn get(
  id: Uuid,
) -> program_types.Program(option.Option(job_log_model.JobLog)) {
  program.perform_db(get_effect(id, program.succeed))
}

pub fn delete_before(before: Timestamp) -> program_types.Program(Nil) {
  program.perform_db(
    delete_before_effect(before, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

fn delete_before_effect(
  before: Timestamp,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.log(job_log_algebra.DeleteJobLogBefore(before: before, next: next))
}

fn list_effect(
  request: job_log_dto.ListJobLogsRequest,
  next: fn(List(job_log_model.JobLog)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.log(job_log_algebra.ListJobLogs(request: request, next: next))
}

fn get_effect(
  id: Uuid,
  next: fn(option.Option(job_log_model.JobLog)) -> next,
) -> program_types.DbEffect(next) {
  job_effect.log(job_log_algebra.GetJobLog(id: id, next: next))
}
