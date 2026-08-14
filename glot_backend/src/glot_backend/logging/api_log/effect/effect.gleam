import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_backend/logging/api_log/effect/algebra as api_log_algebra
import glot_backend/logging/effect/effect as logging_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_core/admin/api_log_dto
import glot_core/api_log_model.{type ApiLogDetail, type ApiLogSummary}
import youid/uuid.{type Uuid}

pub fn list(
  request: api_log_dto.ListApiLogsRequest,
) -> program_types.Program(List(ApiLogSummary)) {
  program.perform_db(list_effect(request, program.succeed))
}

pub fn get(id: Uuid) -> program_types.Program(Option(ApiLogDetail)) {
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
  logging_effect.api_log(api_log_algebra.DeleteApiLogBefore(
    before: before,
    next: next,
  ))
}

fn list_effect(
  request: api_log_dto.ListApiLogsRequest,
  next: fn(List(ApiLogSummary)) -> next,
) -> program_types.DbEffect(next) {
  logging_effect.api_log(api_log_algebra.ListApiLogs(
    request: request,
    next: next,
  ))
}

fn get_effect(
  id: Uuid,
  next: fn(Option(ApiLogDetail)) -> next,
) -> program_types.DbEffect(next) {
  logging_effect.api_log(api_log_algebra.GetApiLog(id: id, next: next))
}
