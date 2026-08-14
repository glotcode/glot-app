import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/login_token as login_token_algebra
import glot_backend/auth/ports/login_token_store.{type LoginTokenStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: login_token_algebra.Effect(next_program),
  store: LoginTokenStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    login_token_algebra.ListLoginTokensByEmail(
      email:,
      created_since:,
      limit:,
      next:,
    ) ->
      measured_interpreter.run_or_fail(
        fn() { store.list_by_email(email, created_since, limit) },
        next,
        map_error: error.database_query_error,
        name: trace_name(login_token_algebra.ListLoginTokensByEmailEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    login_token_algebra.CreateLoginToken(login_token: login_token, next: next) ->
      measured_interpreter.run(
        fn() { store.create(login_token) },
        next,
        name: trace_name(login_token_algebra.CreateLoginTokenEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    login_token_algebra.UpdateLoginToken(login_token: login_token, next: next) ->
      measured_interpreter.run(
        fn() { store.update(login_token) },
        next,
        name: trace_name(login_token_algebra.UpdateLoginTokenEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    login_token_algebra.DeleteLoginTokensBefore(before: before, next: next) ->
      measured_interpreter.run(
        fn() { store.delete_before(before) },
        next,
        name: trace_name(login_token_algebra.DeleteLoginTokensBeforeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    login_token_algebra.InvalidateLoginTokensByEmails(
      old_email:,
      new_email:,
      timestamp:,
      next:,
    ) ->
      measured_interpreter.run(
        fn() { store.invalidate_by_emails(old_email, new_email, timestamp) },
        next,
        name: trace_name(
          login_token_algebra.InvalidateLoginTokensByEmailsEffectName,
        ),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: login_token_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.LoginTokenName(name))
}
