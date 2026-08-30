import gleam/erlang/process
import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/run_code/ports/runner as run_code_runner
import glot_backend/snippet/ports/store as snippet_store
import glot_backend/snippet_runnability/domain/check_next
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/error/run_request_error
import glot_backend/system/effect/program
import glot_backend/system/effect/service_ports
import glot_backend/system/effect/system_ports
import glot_backend/system/effect/transaction/transaction_effect
import glot_core/language
import glot_core/run
import glot_core/snippet/runnability
import glot_core/snippet/snippet_model
import support/integration/adapter/service_ports as test_service_ports
import support/integration/adapter/snippet as test_snippet_adapter
import support/integration/adapter/state
import support/integration/adapter/transaction as test_transaction_adapter
import support/integration/fixture
import support/integration/model
import support/integration/runner

pub fn unsupported_language_is_stored_as_not_runnable_without_execution_test() {
  let test_fixture = fixture.integration_fixture([], [], option.None)
  let snippet =
    snippet_model.Snippet(..test_fixture.snippet, language: language.Plaintext)
  let checks = process.new_subject()
  let attempts = process.new_subject()
  let executions = process.new_subject()

  let #(result, _) =
    runner.run_test_program_with(
      check_and_finalize(5),
      test_fixture.ctx,
      test_fixture.state,
      fn(test_state) {
        services(
          test_state,
          snippet,
          0,
          checks,
          attempts,
          executions,
          Ok(Error(run.FailedRun("must not execute"))),
        )
      },
    )

  let assert Ok(check_next.Processed(_)) = result
  let assert Ok(runnability.CheckResult(is_runnable:, checked_at:)) =
    process.receive(checks, 0)
  assert is_runnable == False
  assert checked_at == fixture.test_system_time()
  assert process.receive(attempts, 0) == Error(Nil)
  assert process.receive(executions, 0) == Error(Nil)
}

pub fn successful_execution_without_error_is_runnable_test() {
  let test_fixture = fixture.integration_fixture([], [], option.None)
  let checks = process.new_subject()
  let attempts = process.new_subject()
  let executions = process.new_subject()

  let #(result, _) =
    runner.run_test_program_with(
      check_and_finalize(5),
      test_fixture.ctx,
      test_fixture.state,
      fn(test_state) {
        services(
          test_state,
          test_fixture.snippet,
          0,
          checks,
          attempts,
          executions,
          Ok(Ok(run.SuccessfulRun(1, "1\n", "", ""))),
        )
      },
    )

  let assert Ok(check_next.Processed(_)) = result
  let assert Ok(runnability.CheckResult(is_runnable:, ..)) =
    process.receive(checks, 0)
  assert is_runnable == True
  let assert Ok(#(_, expected_updated_at)) = process.receive(attempts, 0)
  assert expected_updated_at == test_fixture.snippet.updated_at
  let assert Ok(request) = process.receive(executions, 0)
  assert request.image == language.container_image(language.Python)
  assert request.payload.run_instructions.run_command == "python main.py"
}

pub fn execution_error_output_is_not_runnable_test() {
  let test_fixture = fixture.integration_fixture([], [], option.None)
  let checks = process.new_subject()
  let attempts = process.new_subject()
  let executions = process.new_subject()

  let #(result, _) =
    runner.run_test_program_with(
      check_and_finalize(5),
      test_fixture.ctx,
      test_fixture.state,
      fn(test_state) {
        services(
          test_state,
          test_fixture.snippet,
          0,
          checks,
          attempts,
          executions,
          Ok(Ok(run.SuccessfulRun(1, "", "", "compile failed"))),
        )
      },
    )

  let assert Ok(check_next.Processed(_)) = result
  let assert Ok(runnability.CheckResult(is_runnable:, ..)) =
    process.receive(checks, 0)
  assert is_runnable == False
}

pub fn infrastructure_failure_is_retried_without_classifying_snippet_test() {
  let test_fixture = fixture.integration_fixture([], [], option.None)
  let checks = process.new_subject()
  let attempts = process.new_subject()
  let executions = process.new_subject()

  let #(result, _) =
    runner.run_test_program_with(
      check_and_finalize(5),
      test_fixture.ctx,
      test_fixture.state,
      fn(test_state) {
        services(
          test_state,
          test_fixture.snippet,
          0,
          checks,
          attempts,
          executions,
          Error(run_request_error.ServerRunRequestError),
        )
      },
    )

  let assert Error(_) = result
  assert process.receive(checks, 0) == Error(Nil)
  assert process.receive(attempts, 0) != Error(Nil)
  assert process.receive(executions, 0) != Error(Nil)
}

fn check_and_finalize(max_attempts) {
  use outcome <- program.and_then(check_next.check_next(
    fixture.test_context(),
    max_attempts,
  ))
  case outcome {
    check_next.NoCandidate -> program.succeed(outcome)
    check_next.Processed(finalize) -> {
      use _ <- program.and_then(transaction_effect.run(finalize))
      program.succeed(outcome)
    }
  }
}

fn services(
  test_state,
  snippet,
  candidate_attempts,
  checks,
  attempts,
  executions,
  execution_result,
) -> service_ports.ServicePorts {
  state.update(test_state, fn(db) {
    let config =
      dynamic_config.DynamicConfig(
        ..db.dynamic_config,
        docker_run: option.Some(run_code_config.DockerRunConfig(
          "http://docker-run",
          "token",
          1000,
        )),
      )
    model.TestState(..db, dynamic_config: config)
  })
  let base_services =
    test_service_ports.defaults(test_state)
    |> test_service_ports.with_app_config(test_state)
  let snippets =
    snippet_store.Store(
      ..test_snippet_adapter.defaults(),
      get_newest_unchecked_runnability: fn() {
        Ok(
          option.Some(runnability.Candidate(
            snippet,
            snippet.updated_at,
            candidate_attempts,
          )),
        )
      },
      increment_runnability_check_attempts: fn(id, expected_updated_at) {
        process.send(attempts, #(id, expected_updated_at))
        Ok(runnability.Stored)
      },
      store_runnability: fn(_, _, check_result) {
        process.send(checks, check_result)
        Ok(runnability.Stored)
      },
    )
  let database = database_ports.with_snippet(base_services.database, snippets)
  let system =
    system_ports.SystemPorts(
      ..base_services.system,
      run_code: run_code_runner.Runner(run: fn(_, request, _) {
        process.send(executions, request)
        execution_result
      }),
    )
  service_ports.ServicePorts(
    ..base_services,
    database: database,
    system: system,
    transaction: test_transaction_adapter.new(test_state, database),
  )
}
