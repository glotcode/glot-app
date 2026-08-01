import gleam/option
import gleam/result
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/effect/passkey as passkey_effect
import glot_backend/auth/passkey/effect/effect as webauthn_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error.{type Error}
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/passkey_challenge_model
import glot_core/auth/passkey_dto.{type BeginPasskeyLoginResponse}
import glot_core/helpers/timestamp_helpers
import glot_core/public_action

pub fn begin_passkey_login(
  request_ctx: RequestContext,
) -> Program(BeginPasskeyLoginResponse) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.BeginPasskeyLoginAction),
    actor: api_action_policy.Anonymous,
  ))
  use challenge_id <- program.and_then(basic_effect.uuid_v7())
  let passkey_config = dynamic_config.passkey_config(config)
  use challenge_result <- program.and_then(
    webauthn_effect.new_authentication_challenge(
      passkey_config.origin,
      passkey_config.rp_id,
      "required",
      [],
    ),
  )
  use challenge_result <- program.and_then(
    challenge_result
    |> result.map_error(error_from_webauthn)
    |> program.from_result,
  )
  let #(challenge, allow_credential_ids, challenge_state) = challenge_result
  let challenge_record =
    passkey_challenge_model.PasskeyChallenge(
      id: challenge_id,
      user_id: option.None,
      flow: passkey_challenge_model.PasskeyAuthenticationChallenge,
      challenge_state: challenge_state,
      created_at: ctx.timestamp,
      expires_at: timestamp_helpers.add_seconds(
        ctx.timestamp,
        passkey_config.challenge_timeout_seconds,
      ),
    )
  use _ <- program.and_then(
    transaction_program.sequence([
      passkey_effect.create_passkey_challenge_tx(challenge_record),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )

  program.succeed(passkey_dto.BeginPasskeyLoginResponse(
    challenge_id: challenge_id,
    challenge: challenge,
    rp_id: passkey_config.rp_id,
    allow_credential_ids: allow_credential_ids,
    timeout_seconds: passkey_config.challenge_timeout_seconds,
    user_verification: "required",
  ))
}

fn error_from_webauthn(message: String) -> Error {
  error.infra(infra_error.RunRequestClientError(message))
}
