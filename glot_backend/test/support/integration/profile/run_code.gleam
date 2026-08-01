import glot_backend/system/effect/error
import glot_backend/system/effect/program_types
import glot_backend/system/effect/service_ports.{type ServicePorts}
import glot_backend/system/request/context
import glot_core/run.{type RunResult}
import support/integration/adapter/service_ports as test_service_ports
import support/integration/adapter/state
import support/integration/adapter/system
import support/integration/model
import support/integration/runner

pub fn run_test_program(
  program: program_types.Program(a),
  ctx: context.Context,
  state: model.TestState,
) -> #(Result(a, error.Error), model.TestState) {
  runner.run_test_program_with(program, ctx, state, service_ports)
}

pub fn run_execution_test_program(
  program: program_types.Program(a),
  ctx: context.Context,
  state: model.TestState,
  execution_result: RunResult,
) -> #(Result(a, error.Error), model.TestState) {
  runner.run_test_program_with(program, ctx, state, fn(test_state) {
    run_execution_service_ports(test_state, execution_result)
  })
}

pub fn run_execution_with_run_log_failure_test_program(
  program: program_types.Program(a),
  ctx: context.Context,
  state: model.TestState,
  execution_result: RunResult,
) -> #(Result(a, error.Error), model.TestState) {
  runner.run_test_program_with(program, ctx, state, fn(test_state) {
    test_service_ports.defaults(test_state)
    |> test_service_ports.with_app_config(test_state)
    |> test_service_ports.with_user_action(test_state)
    |> test_service_ports.with_system(
      system.defaults(test_state)
      |> system.with_run_code_result(execution_result),
    )
  })
}

pub fn service_ports(test_state: state.State) -> ServicePorts {
  test_service_ports.defaults(test_state)
  |> test_service_ports.with_app_config(test_state)
  |> test_service_ports.with_system(
    system.defaults(test_state) |> system.with_run_code,
  )
}

fn run_execution_service_ports(
  test_state: state.State,
  execution_result: RunResult,
) -> ServicePorts {
  test_service_ports.defaults(test_state)
  |> test_service_ports.with_app_config(test_state)
  |> test_service_ports.with_user_action(test_state)
  |> test_service_ports.with_run_log(test_state)
  |> test_service_ports.with_system(
    system.defaults(test_state)
    |> system.with_run_code_result(execution_result),
  )
}
