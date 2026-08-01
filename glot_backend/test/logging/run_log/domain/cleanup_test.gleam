import gleam/dict
import gleam/option
import gleam/result
import gleam/time/timestamp
import glot_backend/logging/run_log/domain/cleanup as clean_run_log_domain
import glot_backend/system/request/context
import glot_core/language
import glot_core/run_log_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/logging as runner
import support/integration/store/common

pub fn clean_run_log_deletes_only_old_rows_test() {
  let old_run_log =
    run_log_model.RunLog(
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000d01"),
      request_id: fixture.test_request_id(),
      created_at: timestamp.from_unix_seconds_and_nanoseconds(1_697_300_000, 0),
      session_id: option.None,
      user_id: option.None,
      language: language.Python,
      outcome: run_log_model.RunSucceeded,
      duration_ns: option.Some(1000),
      failure_message: option.None,
    )
  let recent_run_log =
    run_log_model.RunLog(
      ..old_run_log,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000d02"),
      created_at: timestamp.from_unix_seconds_and_nanoseconds(1_699_900_000, 0),
    )
  let boundary_run_log =
    run_log_model.RunLog(
      ..old_run_log,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000d03"),
      created_at: timestamp.from_unix_seconds_and_nanoseconds(1_697_408_000, 0),
    )
  let ctx =
    context.Context(
      ..fixture.test_context(),
      timestamp: timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 0),
    )
  let db =
    model.TestState(
      ..fixture.empty_test_state(),
      run_logs: dict.from_list([
        #(common.uuid_key(old_run_log.id), old_run_log),
        #(common.uuid_key(boundary_run_log.id), boundary_run_log),
        #(common.uuid_key(recent_run_log.id), recent_run_log),
      ]),
    )

  let #(run_result, updated_db) =
    runner.run_test_program(clean_run_log_domain.clean_run_log(ctx), ctx, db)

  assert run_result == Ok(Nil)
  assert dict.get(updated_db.run_logs, common.uuid_key(old_run_log.id))
    == Error(Nil)
  assert dict.get(updated_db.run_logs, common.uuid_key(recent_run_log.id))
    == Ok(recent_run_log)
  assert dict.get(updated_db.run_logs, common.uuid_key(boundary_run_log.id))
    == Ok(boundary_run_log)
}

pub fn clean_run_log_propagates_delete_failure_test() {
  let ctx = fixture.test_context()
  let db = fixture.empty_test_state()

  let #(run_result, updated_db) =
    runner.run_with_run_log_failure(
      clean_run_log_domain.clean_run_log(ctx),
      ctx,
      db,
    )

  assert result.is_error(run_result)
  assert updated_db.run_logs == db.run_logs
}
