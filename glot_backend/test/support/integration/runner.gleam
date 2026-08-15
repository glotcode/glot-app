import exception
import glot_backend/system/effect/error
import glot_backend/system/effect/interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/effect/runtime
import glot_backend/system/effect/service_ports.{type ServicePorts}
import glot_backend/system/request/context
import support/integration/adapter/state
import support/integration/model

pub fn run_test_program_with(
  program: program_types.Program(a),
  ctx: context.Context,
  initial: model.TestState,
  build_services: fn(state.State) -> ServicePorts,
) -> #(Result(a, error.Error), model.TestState) {
  let #(result, db, _) =
    run_test_program_with_effect_state(program, ctx, initial, build_services)
  #(result, db)
}

pub fn run_test_program_with_effect_state(
  program: program_types.Program(a),
  ctx: context.Context,
  initial: model.TestState,
  build_services: fn(state.State) -> ServicePorts,
) -> #(Result(a, error.Error), model.TestState, program_state.State) {
  let test_state = state.new(initial)
  use <- exception.defer(fn() { state.stop(test_state) })
  let effect_runtime = runtime.new(build_services(test_state))
  let #(result, effect_state) = interpreter.run(program, effect_runtime, ctx)
  #(result, state.get(test_state), effect_state)
}
