import glot_backend/analytics/effect/algebra as analytics_algebra
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/effect/transaction/transaction_program

pub fn perform_wraps_application_effect_test() {
  let effect =
    program_types.BasicEffect(
      basic_algebra.SystemTime(fn(_) { program.succeed(1) }),
    )

  let assert program_types.Impure(program_types.BasicEffect(basic_algebra.SystemTime(
    _,
  ))) = program.perform(effect)
}

pub fn perform_db_wraps_database_effect_test() {
  let effect =
    program_types.AnalyticsEffect(
      analytics_algebra.GetMaxCompletedMetricsDay(next: fn(_) {
        program.succeed(1)
      }),
    )

  let assert program_types.Impure(program_types.DbEffect(program_types.AnalyticsEffect(analytics_algebra.GetMaxCompletedMetricsDay(
    next: _,
  )))) = program.perform_db(effect)
}

pub fn transaction_perform_wraps_database_effect_test() {
  let effect =
    program_types.AnalyticsEffect(
      analytics_algebra.GetMaxCompletedMetricsDay(next: fn(_) {
        transaction_program.succeed(1)
      }),
    )

  let assert program_types.TxImpure(program_types.AnalyticsEffect(analytics_algebra.GetMaxCompletedMetricsDay(
    next: _,
  ))) = transaction_program.perform(effect)
}

pub fn mapped_result_converts_success_and_failure_test() {
  let assert program_types.Pure(7) =
    program.from_mapped_result(Ok(7), map_error: error.database_command_error)

  let failed: Result(Int, db_error.DbCommandError) =
    Error(db_error.DbCommandError("failed"))
  let expected_error =
    error.database_command_error(db_error.DbCommandError("failed"))

  let assert program_types.Fail(program_error) =
    program.from_mapped_result(failed, map_error: error.database_command_error)
  assert program_error == expected_error

  let assert program_types.TxPure(7) =
    transaction_program.from_mapped_result(
      Ok(7),
      map_error: error.database_command_error,
    )
  let assert program_types.TxFail(transaction_error) =
    transaction_program.from_mapped_result(
      failed,
      map_error: error.database_command_error,
    )
  assert transaction_error == expected_error
}
