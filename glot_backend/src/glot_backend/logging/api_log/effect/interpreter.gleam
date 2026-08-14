import glot_backend/logging/api_log/effect/algebra as api_log_algebra
import glot_backend/logging/api_log/ports/store.{type Store}
import glot_backend/logging/effect/algebra as logging_algebra
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: api_log_algebra.ApiLogEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    api_log_algebra.ListApiLogs(request:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.list(request) },
        next,
        map_error: error.database_query_error,
        name: trace_name(api_log_algebra.ListApiLogsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    api_log_algebra.GetApiLog(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get(id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(api_log_algebra.GetApiLogEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    api_log_algebra.DeleteApiLogBefore(before:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: trace_name(api_log_algebra.DeleteApiLogBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: api_log_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.LoggingEffectName(logging_algebra.ApiLogName(name))
}
