import gleam/dict
import gleam/option
import gleam/result
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/run_code/domain/run as run_domain
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error
import glot_backend/system/request/context
import glot_backend/system/request/hydrated_context as request_context
import glot_core/language
import glot_core/run
import glot_core/run_log_model
import glot_core/snippet/snippet_model
import glot_core/validation_error
import support/integration/fixture
import support/integration/model
import support/integration/profile/run_code as runner
import support/integration/store/common
import youid/uuid.{type Uuid}

pub fn successful_run_records_the_action_and_run_log_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000696")
  let run_log_id = fixture.must_uuid("00000000-0000-0000-0000-000000000695")
  let #(ctx, config, state, request) = test_setup([user_action_id, run_log_id])
  let execution =
    run.SuccessfulRun(duration: 42, stdout: "hello\n", stderr: "", error: "")

  let #(result, db) =
    runner.run_execution_test_program(
      run_domain.run(request_context.new(ctx, config), request),
      ctx,
      state,
      Ok(execution),
    )

  assert result == Ok(Ok(execution))
  let assert Ok(run_log) = dict.get(db.run_logs, common.uuid_key(run_log_id))
  assert run_log.language == language.Python
  assert run_log.outcome == run_log_model.RunSucceeded
  assert run_log.duration_ns == option.Some(42)
  assert run_log.failure_message == option.None
  assert db.user_action_count == 1
  assert db.write_steps == ["create_run_log", "create_user_action"]
}

pub fn failed_run_records_the_failure_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000694")
  let run_log_id = fixture.must_uuid("00000000-0000-0000-0000-000000000693")
  let #(ctx, config, state, request) = test_setup([user_action_id, run_log_id])
  let execution = run.FailedRun(message: "process exited with status 1")

  let #(result, db) =
    runner.run_execution_test_program(
      run_domain.run(request_context.new(ctx, config), request),
      ctx,
      state,
      Error(execution),
    )

  assert result == Ok(Error(execution))
  let assert Ok(run_log) = dict.get(db.run_logs, common.uuid_key(run_log_id))
  assert run_log.outcome == run_log_model.RunFailed
  assert run_log.duration_ns == option.None
  assert run_log.failure_message == option.Some(execution.message)
  assert db.user_action_count == 1
}

pub fn invalid_run_performs_no_effects_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000692")
  let run_log_id = fixture.must_uuid("00000000-0000-0000-0000-000000000691")
  let next_uuids = [user_action_id, run_log_id]
  let #(ctx, config, state, request) = test_setup(next_uuids)
  let invalid_ctx =
    context.Context(
      ..ctx,
      client_info: context.ClientInfo(
        ..ctx.client_info,
        session_token: option.Some("invalid-session-token"),
      ),
    )
  let invalid_request = run.RunRequest(..request, image: "unknown:image")
  let execution = run.SuccessfulRun(0, "", "", "")

  let #(result, db) =
    runner.run_execution_test_program(
      run_domain.run(request_context.new(invalid_ctx, config), invalid_request),
      invalid_ctx,
      state,
      Ok(execution),
    )

  assert result
    == Error(
      error.validation(validation_error.UnknownRunLanguage("unknown:image")),
    )
  assert db.next_uuids == next_uuids
  assert db.write_steps == []
  assert dict.is_empty(db.run_logs)
}

pub fn run_log_failure_rolls_back_the_user_action_test() {
  let user_action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000690")
  let run_log_id = fixture.must_uuid("00000000-0000-0000-0000-000000000689")
  let #(ctx, config, state, request) = test_setup([user_action_id, run_log_id])
  let execution = run.SuccessfulRun(42, "hello\n", "", "")

  let #(run_result, db) =
    runner.run_execution_with_run_log_failure_test_program(
      run_domain.run(request_context.new(ctx, config), request),
      ctx,
      state,
      Ok(execution),
    )

  assert result.is_error(run_result)
  assert db.user_action_count == 0
  assert db.write_steps == []
  assert dict.is_empty(db.run_logs)
}

fn test_setup(next_uuids: List(Uuid)) {
  let ctx = fixture.anonymous_test_context()
  let config =
    dynamic_config.DynamicConfig(
      ..fixture.test_dynamic_config(),
      docker_run: option.Some(run_code_config.DockerRunConfig(
        base_url: "http://docker-run.test",
        access_token: "token",
        default_timeout_ms: 1000,
      )),
    )
  let state =
    model.TestState(
      ..fixture.empty_test_state(),
      dynamic_config: config,
      next_uuids: next_uuids,
    )
  let request =
    run.RunRequest(
      image: language.container_image(language.Python),
      payload: run.RunRequestPayload(
        run_instructions: language.RunInstructions([], "python main.py"),
        files: [snippet_model.File(name: "main.py", content: "print('hello')")],
        stdin: option.None,
      ),
    )

  #(ctx, config, state, request)
}
