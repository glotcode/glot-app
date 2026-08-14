import gleam/time/timestamp.{type Timestamp}
import glot_backend/logging/effect/effect as logging_effect
import glot_backend/logging/page_log/effect/algebra as page_log_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types

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
  logging_effect.page_log(page_log_algebra.DeletePageLogBefore(
    before: before,
    next: next,
  ))
}
