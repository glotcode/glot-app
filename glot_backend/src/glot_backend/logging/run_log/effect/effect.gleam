import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/logging/effect/effect as logging_effect
import glot_backend/logging/run_log/effect/algebra as run_log_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program
import glot_core/admin/run_log_dto
import glot_core/run_log_model.{type RunLog}
import youid/uuid.{type Uuid}

pub fn create(run_log: RunLog) -> program_types.Program(Nil) {
  program.perform_db(
    create_effect(run_log, program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn create_tx(run_log: RunLog) -> program_types.TransactionProgram(Nil) {
  transaction_program.perform(
    create_effect(run_log, transaction_program.from_mapped_result(
      _,
      map_error: error.database_command_error,
    )),
  )
}

pub fn list(
  request: run_log_dto.ListRunLogsRequest,
) -> program_types.Program(List(RunLog)) {
  program.perform_db(list_effect(request, program.succeed))
}

pub fn get(id: Uuid) -> program_types.Program(Option(RunLog)) {
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

fn create_effect(
  run_log: RunLog,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  logging_effect.run_log(run_log_algebra.CreateRunLog(
    run_log: run_log,
    next: next,
  ))
}

fn list_effect(
  request: run_log_dto.ListRunLogsRequest,
  next: fn(List(RunLog)) -> next,
) -> program_types.DbEffect(next) {
  logging_effect.run_log(run_log_algebra.ListRunLogs(
    request: request,
    next: next,
  ))
}

fn get_effect(
  id: Uuid,
  next: fn(Option(RunLog)) -> next,
) -> program_types.DbEffect(next) {
  logging_effect.run_log(run_log_algebra.GetRunLog(id: id, next: next))
}

fn delete_before_effect(
  before: Timestamp,
  next: fn(Result(Nil, db_error.DbCommandError)) -> next,
) -> program_types.DbEffect(next) {
  logging_effect.run_log(run_log_algebra.DeleteRunLogBefore(
    before: before,
    next: next,
  ))
}
