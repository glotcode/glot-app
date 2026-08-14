import glot_backend/logging/effect/algebra as logging_algebra
import glot_backend/logging/run_log/effect/algebra as run_log_algebra
import glot_backend/logging/run_log/ports/store.{type Store}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: run_log_algebra.RunLogEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    run_log_algebra.CreateRunLog(run_log:, next:) ->
      measured_interpreter.run(
        fn() { store.create(run_log) },
        next,
        name: trace_name(run_log_algebra.CreateRunLogEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    run_log_algebra.ListRunLogs(request:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.list(request) },
        next,
        map_error: error.database_query_error,
        name: trace_name(run_log_algebra.ListRunLogsEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    run_log_algebra.GetRunLog(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get(id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(run_log_algebra.GetRunLogEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    run_log_algebra.DeleteRunLogBefore(before:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: trace_name(run_log_algebra.DeleteRunLogBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: run_log_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.LoggingEffectName(logging_algebra.RunLogName(name))
}
