import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/email_change
import glot_backend/auth/ports/email_change_token_store.{
  type EmailChangeTokenStore,
}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: email_change.Effect(next_program),
  store: EmailChangeTokenStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    email_change.ListEmailChangeTokensByUserId(
      user_id:,
      created_since:,
      limit:,
      next:,
    ) ->
      measured_interpreter.run_or_fail(
        fn() { store.list_by_user_id(user_id, created_since, limit) },
        next,
        map_error: error.database_query_error,
        name: trace_name(email_change.ListEmailChangeTokensByUserIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    email_change.ListEmailChangeTokensByUserIdForUpdate(
      user_id:,
      created_since:,
      limit:,
      next:,
    ) ->
      measured_interpreter.run_or_fail(
        fn() { store.list_by_user_id_for_update(user_id, created_since, limit) },
        next,
        map_error: error.database_query_error,
        name: trace_name(
          email_change.ListEmailChangeTokensByUserIdForUpdateEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    email_change.CreateEmailChangeToken(token:, next:) ->
      measured_interpreter.run(
        fn() { store.create(token) },
        next,
        name: trace_name(email_change.CreateEmailChangeTokenEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    email_change.UpdateEmailChangeToken(token:, next:) ->
      measured_interpreter.run(
        fn() { store.update(token) },
        next,
        name: trace_name(email_change.UpdateEmailChangeTokenEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    email_change.DeleteEmailChangeTokensBefore(before:, next:) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: trace_name(email_change.DeleteEmailChangeTokensBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: email_change.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.EmailChangeName(name))
}
