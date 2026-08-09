import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/passkey/shared as passkey_shared_domain
import glot_backend/auth/domain/session/issue.{type SessionIssueResult} as session_issue_domain
import glot_backend/auth/effect/passkey as passkey_effect
import glot_backend/auth/effect/session as session_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/auth/error as auth_error
import glot_backend/auth/passkey/effect/effect as webauthn_effect
import glot_backend/request_policy/api_action.{type ActionActor} as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/passkey_challenge_model
import glot_core/auth/passkey_credential_model.{type PasskeyCredential}
import glot_core/auth/passkey_dto.{type FinishPasskeyLoginRequest}
import glot_core/auth/user_model
import glot_core/public_action

pub fn finish_passkey_login(
  request_ctx: RequestContext,
  request: FinishPasskeyLoginRequest,
) -> Program(SessionIssueResult) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use credential_id <- program.and_then(passkey_shared_domain.decode_base64url(
    "credentialId",
    request.credential_id,
  ))
  use maybe_credential <- program.and_then(
    passkey_effect.get_passkey_credential_by_credential_id(credential_id),
  )
  use actor <- program.and_then(actor_from_credential(maybe_credential))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.FinishPasskeyLoginAction),
    actor: actor,
  ))
  use challenge <- program.and_then(
    passkey_effect.get_passkey_challenge_by_id(request.challenge_id)
    |> program.and_then(program.from_option(
      _,
      error.auth(auth_error.PasskeyChallengeNotFound),
    )),
  )
  use challenge <- program.and_then(passkey_shared_domain.require_flow(
    challenge,
    passkey_challenge_model.PasskeyAuthenticationChallenge,
  ))
  use challenge <- program.and_then(passkey_shared_domain.require_not_expired(
    challenge,
    ctx.timestamp,
  ))
  use matched_credential <- program.and_then(program.from_option(
    maybe_credential,
    error.auth(auth_error.InvalidPasskeyAssertion),
  ))
  use user <- program.and_then(
    user_effect.get_user_by_id(matched_credential.user_id)
    |> program.and_then(program.from_option(
      _,
      error.auth(auth_error.InvalidPasskeyAssertion),
    )),
  )
  use credentials <- program.and_then(
    passkey_effect.list_passkey_credentials_by_user_id(
      matched_credential.user_id,
    ),
  )
  use matched_credential <- program.and_then(program.from_option(
    find_credential(credentials, credential_id),
    error.auth(auth_error.InvalidPasskeyAssertion),
  ))
  use authenticator_data <- program.and_then(
    passkey_shared_domain.decode_base64url(
      "authenticatorData",
      request.authenticator_data,
    ),
  )
  use signature <- program.and_then(passkey_shared_domain.decode_base64url(
    "signature",
    request.signature,
  ))
  use authentication_result <- program.and_then(webauthn_effect.authenticate(
    credential_id,
    authenticator_data,
    signature,
    request.client_data_json,
    passkey_shared_domain.challenge_state(challenge),
    passkey_shared_domain.credential_entries(credentials),
  ))
  use authentication_result <- program.and_then(
    authentication_result
    |> result.map_error(fn(_) { error.auth(auth_error.InvalidPasskeyAssertion) })
    |> program.from_result,
  )
  let #(sign_count, _aaguid) = authentication_result
  use _ <- program.and_then(validate_sign_count(matched_credential, sign_count))
  let updated_credential =
    passkey_credential_model.mark_used(
      matched_credential,
      sign_count,
      ctx.timestamp,
    )
  let updated_user = user.identity |> user_model.mark_last_login(ctx.timestamp)
  let auth_config = dynamic_config.auth_config(config)
  use _ <- program.and_then(
    basic_effect.info(log.singleton(log.uuid("user_id", updated_user.id))),
  )

  use session_issue <- program.and_then(
    session_issue_domain.issue_session_for_user(ctx, updated_user.id),
  )
  use _ <- program.and_then(
    transaction_program.sequence([
      passkey_effect.update_passkey_credential_tx(updated_credential),
      passkey_effect.delete_passkey_challenge_tx(challenge.id),
      user_effect.update_user_last_login_tx(
        updated_user.id,
        updated_user.last_login_at,
      ),
      session_effect.create_session_tx(session_issue.session),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )
  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session_issue.session.id),
        log.bool("is_first_login", False),
      ]),
    ),
  )

  program.succeed(session_issue_domain.SessionIssueResult(
    session_token: session_issue.session_token,
    session_cookie_max_age: auth_config.session_cookie_max_age,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(FinishPasskeyLoginRequest) {
  program.decode_dynamic(data, passkey_dto.finish_login_request_decoder())
}

fn actor_from_credential(
  credential: Option(PasskeyCredential),
) -> Program(ActionActor) {
  case credential {
    option.Some(credential) ->
      user_effect.get_user_by_id(credential.user_id)
      |> program.map(api_action_policy.actor_from_user)
    option.None -> program.succeed(api_action_policy.Anonymous)
  }
}

fn find_credential(
  credentials: List(PasskeyCredential),
  credential_id: BitArray,
) -> Option(PasskeyCredential) {
  credentials
  |> list.find(fn(credential) { credential.credential_id == credential_id })
  |> option.from_result()
}

fn validate_sign_count(
  credential: PasskeyCredential,
  next_sign_count: Int,
) -> Program(Nil) {
  case
    credential.sign_count > 0
    && next_sign_count > 0
    && next_sign_count <= credential.sign_count
  {
    True -> program.fail(error.auth(auth_error.InvalidPasskeyAssertion))
    False -> program.succeed(Nil)
  }
}
