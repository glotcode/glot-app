import glot_backend/system/effect/error
import glot_backend/system/effect/program_types
import glot_backend/system/effect/service_ports.{type ServicePorts}
import glot_backend/system/request/context
import support/integration/adapter/service_ports as test_service_ports
import support/integration/adapter/state
import support/integration/model
import support/integration/runner

pub fn run_test_program(
  program: program_types.Program(a),
  ctx: context.Context,
  state: model.TestState,
) -> #(Result(a, error.Error), model.TestState) {
  runner.run_test_program_with(program, ctx, state, service_ports)
}

pub fn run_with_run_log_failure(
  program: program_types.Program(a),
  ctx: context.Context,
  initial: model.TestState,
) -> #(Result(a, error.Error), model.TestState) {
  runner.run_test_program_with(program, ctx, initial, fn(test_state) {
    test_service_ports.defaults(test_state)
    |> test_service_ports.with_app_config(test_state)
  })
}

pub fn service_ports(test_state: state.State) -> ServicePorts {
  test_service_ports.defaults(test_state)
  |> test_service_ports.with_app_config(test_state)
  |> test_service_ports.with_run_log(test_state)
}
