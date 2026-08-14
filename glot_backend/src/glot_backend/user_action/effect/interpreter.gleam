import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/user_action/effect/algebra as user_action_algebra
import glot_backend/user_action/ports/store.{type Store}

pub fn run(
  effect: user_action_algebra.UserActionEffect(next_program),
  store: Store,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    user_action_algebra.CountUserActions(filter:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.count(filter) },
        next,
        map_error: error.database_query_error,
        name: effect_trace.UserActionEffectName(
          user_action_algebra.CountUserActionsEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    user_action_algebra.CreateUserAction(user_action: user_action, next: next) ->
      measured_interpreter.run(
        fn() { store.create(user_action) },
        next,
        name: effect_trace.UserActionEffectName(
          user_action_algebra.CreateUserActionEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    user_action_algebra.DeleteBefore(before:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: effect_trace.UserActionEffectName(
          user_action_algebra.DeleteBeforeEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}
