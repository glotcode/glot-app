import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/session as session_algebra
import glot_backend/auth/ports/session_store.{type SessionStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/request/context

pub fn run(
  effect: session_algebra.Effect(next_program),
  ctx: context.Context,
  store: SessionStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    session_algebra.ListSessionsByUserId(
      user_id:,
      created_since:,
      last_activity_since:,
      next:,
    ) ->
      measured_interpreter.run_or_fail(
        fn() {
          store.list_by_user_id(user_id, created_since, last_activity_since)
        },
        next,
        map_error: error.database_query_error,
        name: trace_name(session_algebra.ListSessionsByUserIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    session_algebra.GetSessionByToken(token:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_token(ctx.regexes.is_email, token) },
        next,
        map_error: error.database_query_error,
        name: trace_name(session_algebra.GetSessionByTokenEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    session_algebra.GetSessionByTokenForUpdate(token:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_token_for_update(token) },
        next,
        map_error: error.database_query_error,
        name: trace_name(session_algebra.GetSessionByTokenForUpdateEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    session_algebra.GetSessionByPreviousToken(token:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_previous_token(ctx.regexes.is_email, token) },
        next,
        map_error: error.database_query_error,
        name: trace_name(session_algebra.GetSessionByPreviousTokenEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    session_algebra.GetSessionByPreviousTokenForUpdate(token:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_by_previous_token_for_update(token) },
        next,
        map_error: error.database_query_error,
        name: trace_name(
          session_algebra.GetSessionByPreviousTokenForUpdateEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    session_algebra.DeleteSessionsByAccountId(
      account_id: account_id,
      next: next,
    ) ->
      measured_interpreter.run(
        fn() { store.delete_by_account_id(account_id) },
        next,
        name: trace_name(session_algebra.DeleteSessionsByAccountIdEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    session_algebra.DeleteExpiredSessions(
      created_before: created_before,
      last_activity_before: last_activity_before,
      next: next,
    ) ->
      measured_interpreter.run(
        fn() { store.delete_expired(created_before, last_activity_before) },
        next,
        name: trace_name(session_algebra.DeleteExpiredSessionsEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    session_algebra.CreateSession(session: session, next: next) ->
      measured_interpreter.run(
        fn() { store.create(session) },
        next,
        name: trace_name(session_algebra.CreateSessionEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    session_algebra.UpdateSession(session: session, next: next) ->
      measured_interpreter.run(
        fn() { store.update(session) },
        next,
        name: trace_name(session_algebra.UpdateSessionEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    session_algebra.DeleteSession(id: id, next: next) ->
      measured_interpreter.run(
        fn() { store.delete(id) },
        next,
        name: trace_name(session_algebra.DeleteSessionEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: session_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.SessionName(name))
}
