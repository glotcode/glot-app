import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/login_token as login_token_algebra
import glot_backend/auth/ports/login_token_store.{type LoginTokenStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/program_state
import glot_backend/system/runtime/erlang

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
    ) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.list_by_email(email, created_since, limit)
      case result {
        Ok(value) ->
          continue(
            next(value),
            program_state.add_effect_measurement(
              state,
              trace_name(login_token_algebra.ListLoginTokensByEmailEffectName),
              effect_trace.DatabaseReadEffect,
              started_at,
            ),
          )
        Error(error) -> #(
          Error(error.database_query_error(error)),
          program_state.add_effect_measurement(
            state,
            trace_name(login_token_algebra.ListLoginTokensByEmailEffectName),
            effect_trace.DatabaseReadEffect,
            started_at,
          ),
        )
      }
    }
    login_token_algebra.CreateLoginToken(login_token: login_token, next: next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.create(login_token)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          trace_name(login_token_algebra.CreateLoginTokenEffectName),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    login_token_algebra.UpdateLoginToken(login_token: login_token, next: next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.update(login_token)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          trace_name(login_token_algebra.UpdateLoginTokenEffectName),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    login_token_algebra.DeleteLoginTokensBefore(before: before, next: next) -> {
      let started_at = erlang.perf_counter_ns()
      let result = store.delete_before(before)
      continue(
        next(result),
        program_state.add_effect_measurement(
          state,
          trace_name(login_token_algebra.DeleteLoginTokensBeforeEffectName),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    login_token_algebra.InvalidateLoginTokensByEmails(
      old_email:,
      new_email:,
      timestamp:,
      next:,
    ) -> {
      let started_at = erlang.perf_counter_ns()
      continue(
        next(store.invalidate_by_emails(old_email, new_email, timestamp)),
        program_state.add_effect_measurement(
          state,
          trace_name(
            login_token_algebra.InvalidateLoginTokensByEmailsEffectName,
          ),
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
  }
}

fn trace_name(name: login_token_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.LoginTokenName(name))
}
