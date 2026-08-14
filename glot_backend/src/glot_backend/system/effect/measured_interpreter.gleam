import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/program_state
import glot_backend/system/runtime/erlang

pub fn run(
  operation: fn() -> value,
  next: fn(value) -> next_program,
  name name: effect_trace.EffectName,
  kind kind: effect_trace.EffectKind,
  state state: program_state.State,
  continue continue: fn(next_program, program_state.State) ->
    #(output, program_state.State),
) -> #(output, program_state.State) {
  let started_at = erlang.perf_counter_ns()
  let value = operation()
  continue(
    next(value),
    program_state.add_effect_measurement(state, name, kind, started_at),
  )
}

pub fn run_or_fail(
  operation: fn() -> Result(value, operation_error),
  next: fn(value) -> next_program,
  map_error map_error: fn(operation_error) -> error.Error,
  name name: effect_trace.EffectName,
  kind kind: effect_trace.EffectKind,
  state state: program_state.State,
  continue continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  let started_at = erlang.perf_counter_ns()
  let result = operation()
  let measured_state =
    program_state.add_effect_measurement(state, name, kind, started_at)

  case result {
    Ok(value) -> continue(next(value), measured_state)
    Error(operation_error) -> #(
      Error(map_error(operation_error)),
      measured_state,
    )
  }
}

pub fn run_with_kind(
  operation: fn() -> #(value, effect_trace.EffectKind),
  next: fn(value) -> next_program,
  name name: effect_trace.EffectName,
  state state: program_state.State,
  continue continue: fn(next_program, program_state.State) ->
    #(output, program_state.State),
) -> #(output, program_state.State) {
  let started_at = erlang.perf_counter_ns()
  let #(value, kind) = operation()
  continue(
    next(value),
    program_state.add_effect_measurement(state, name, kind, started_at),
  )
}

pub fn run_with_state(
  operation: fn(program_state.State) -> #(value, program_state.State),
  next: fn(value) -> next_program,
  name name: effect_trace.EffectName,
  kind kind: effect_trace.EffectKind,
  state state: program_state.State,
  continue continue: fn(next_program, program_state.State) ->
    #(output, program_state.State),
) -> #(output, program_state.State) {
  let started_at = erlang.perf_counter_ns()
  let #(value, state) = operation(state)
  continue(
    next(value),
    program_state.add_effect_measurement(state, name, kind, started_at),
  )
}
