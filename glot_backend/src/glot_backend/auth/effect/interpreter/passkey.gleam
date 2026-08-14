import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/effect/algebra/passkey as passkey_algebra
import glot_backend/auth/ports/passkey_store.{type PasskeyStore}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state

pub fn run(
  effect: passkey_algebra.Effect(next_program),
  store: PasskeyStore,
  state: program_state.State,
  continue: fn(next_program, program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    passkey_algebra.GetPasskeyCredentialByCredentialId(credential_id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_credential_by_credential_id(credential_id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(
          passkey_algebra.GetPasskeyCredentialByCredentialIdEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.ListPasskeyCredentialsByUserId(user_id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.list_credentials_by_user_id(user_id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(
          passkey_algebra.ListPasskeyCredentialsByUserIdEffectName,
        ),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.GetPasskeyChallengeById(id:, next:) ->
      measured_interpreter.run_or_fail(
        fn() { store.get_challenge_by_id(id) },
        next,
        map_error: error.database_query_error,
        name: trace_name(passkey_algebra.GetPasskeyChallengeByIdEffectName),
        kind: effect_trace.DatabaseReadEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.CreatePasskeyCredential(
      passkey_credential: passkey_credential,
      next: next,
    ) ->
      measured_interpreter.run(
        fn() { store.create_credential(passkey_credential) },
        next,
        name: trace_name(passkey_algebra.CreatePasskeyCredentialEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.CreatePasskeyChallenge(
      passkey_challenge: passkey_challenge,
      next: next,
    ) ->
      measured_interpreter.run(
        fn() { store.create_challenge(passkey_challenge) },
        next,
        name: trace_name(passkey_algebra.CreatePasskeyChallengeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.DeletePasskeyCredential(id: id, next: next) ->
      measured_interpreter.run(
        fn() { store.delete_credential(id) },
        next,
        name: trace_name(passkey_algebra.DeletePasskeyCredentialEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.UpdatePasskeyCredential(
      passkey_credential: passkey_credential,
      next: next,
    ) ->
      measured_interpreter.run(
        fn() { store.update_credential(passkey_credential) },
        next,
        name: trace_name(passkey_algebra.UpdatePasskeyCredentialEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
    passkey_algebra.DeletePasskeyChallenge(id: id, next: next) ->
      measured_interpreter.run(
        fn() { store.delete_challenge(id) },
        next,
        name: trace_name(passkey_algebra.DeletePasskeyChallengeEffectName),
        kind: effect_trace.DatabaseWriteEffect,
        state: state,
        continue: continue,
      )
  }
}

fn trace_name(name: passkey_algebra.EffectName) -> effect_trace.EffectName {
  effect_trace.AuthEffectName(auth_algebra.PasskeyName(name))
}
