import glot_backend/logging/effect/algebra as logging_algebra
import glot_backend/logging/pageview/effect/algebra as pageview_log_algebra
import glot_backend/logging/pageview/ports/store.{type Store}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: pageview_log_algebra.PageviewLogEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    pageview_log_algebra.DeletePageviewLogBefore(before:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: trace_name(pageview_log_algebra.DeletePageviewLogBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(
  name: pageview_log_algebra.EffectName,
) -> effect_trace.EffectName {
  effect_trace.LoggingEffectName(logging_algebra.PageviewName(name))
}
