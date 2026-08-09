import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/email_change
import glot_backend/auth/ports/email_change_token_store.{
  type EmailChangeTokenStore,
}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/program_state
import glot_backend/system/runtime/erlang

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
    ) -> {
      let started_at = erlang.perf_counter_ns()
      case store.list_by_user_id(user_id, created_since, limit) {
        Ok(value) ->
          continue(
            next(value),
            measured(
              state,
              email_change.ListEmailChangeTokensByUserIdEffectName,
              effect_trace.DatabaseReadEffect,
              started_at,
            ),
          )
        Error(err) -> #(
          Error(error.database_query_error(err)),
          measured(
            state,
            email_change.ListEmailChangeTokensByUserIdEffectName,
            effect_trace.DatabaseReadEffect,
            started_at,
          ),
        )
      }
    }
    email_change.ListEmailChangeTokensByUserIdForUpdate(
      user_id:,
      created_since:,
      limit:,
      next:,
    ) -> {
      let started_at = erlang.perf_counter_ns()
      case store.list_by_user_id_for_update(user_id, created_since, limit) {
        Ok(value) ->
          continue(
            next(value),
            measured(
              state,
              email_change.ListEmailChangeTokensByUserIdForUpdateEffectName,
              effect_trace.DatabaseReadEffect,
              started_at,
            ),
          )
        Error(err) -> #(
          Error(error.database_query_error(err)),
          measured(
            state,
            email_change.ListEmailChangeTokensByUserIdForUpdateEffectName,
            effect_trace.DatabaseReadEffect,
            started_at,
          ),
        )
      }
    }
    email_change.CreateEmailChangeToken(token:, next:) -> {
      let started_at = erlang.perf_counter_ns()
      continue(
        next(store.create(token)),
        measured(
          state,
          email_change.CreateEmailChangeTokenEffectName,
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    email_change.UpdateEmailChangeToken(token:, next:) -> {
      let started_at = erlang.perf_counter_ns()
      continue(
        next(store.update(token)),
        measured(
          state,
          email_change.UpdateEmailChangeTokenEffectName,
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
    email_change.DeleteEmailChangeTokensBefore(before:, next:) -> {
      let started_at = erlang.perf_counter_ns()
      continue(
        next(store.delete_before(before)),
        measured(
          state,
          email_change.DeleteEmailChangeTokensBeforeEffectName,
          effect_trace.DatabaseWriteEffect,
          started_at,
        ),
      )
    }
  }
}

fn measured(
  state: program_state.State,
  name: email_change.EffectName,
  kind: effect_trace.EffectKind,
  started_at: Int,
) -> program_state.State {
  program_state.add_effect_measurement(
    state,
    effect_trace.AuthEffectName(auth_algebra.EmailChangeName(name)),
    kind,
    started_at,
  )
}
