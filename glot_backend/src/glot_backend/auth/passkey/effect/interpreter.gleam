import glot_backend/auth/passkey/effect/algebra
import glot_backend/auth/passkey/ports/ceremony.{type Ceremony}
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/effect/measured_interpreter
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types

pub fn run(
  effect: algebra.WebauthnEffect(program_types.Program(a)),
  ceremony: Ceremony,
  state: program_state.State,
  continue: fn(program_types.Program(a), program_state.State) ->
    #(Result(a, error.Error), program_state.State),
) -> #(Result(a, error.Error), program_state.State) {
  case effect {
    algebra.NewRegistrationChallenge(origin, rp_id, user_verification, next) ->
      measured_interpreter.run(
        fn() {
          ceremony.new_registration_challenge(origin, rp_id, user_verification)
        },
        next,
        name: effect_trace.WebauthnEffectName(
          algebra.NewRegistrationChallengeEffectName,
        ),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
    algebra.Register(
      attestation_object,
      client_data_json,
      challenge_state,
      next,
    ) ->
      measured_interpreter.run(
        fn() {
          ceremony.register(
            attestation_object,
            client_data_json,
            challenge_state,
          )
        },
        next,
        name: effect_trace.WebauthnEffectName(algebra.RegisterEffectName),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
    algebra.NewAuthenticationChallenge(
      origin,
      rp_id,
      user_verification,
      credentials,
      next,
    ) ->
      measured_interpreter.run(
        fn() {
          ceremony.new_authentication_challenge(
            origin,
            rp_id,
            user_verification,
            credentials,
          )
        },
        next,
        name: effect_trace.WebauthnEffectName(
          algebra.NewAuthenticationChallengeEffectName,
        ),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
    algebra.Authenticate(
      credential_id,
      authenticator_data,
      signature,
      client_data_json,
      challenge_state,
      credentials,
      next,
    ) ->
      measured_interpreter.run(
        fn() {
          ceremony.authenticate(
            credential_id,
            authenticator_data,
            signature,
            client_data_json,
            challenge_state,
            credentials,
          )
        },
        next,
        name: effect_trace.WebauthnEffectName(algebra.AuthenticateEffectName),
        kind: effect_trace.RuntimeEffect,
        state: state,
        continue: continue,
      )
  }
}
