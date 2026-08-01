import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/passkey as passkey_effect
import glot_backend/auth/error as auth_error
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/passkey_dto.{type DeleteAccountPasskeyRequest}
import glot_core/public_action

pub fn delete_account_passkey(
  request_ctx: RequestContext,
  request: DeleteAccountPasskeyRequest,
) -> Program(Nil) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.DeleteAccountPasskeyAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))
  use credentials <- program.and_then(
    passkey_effect.list_passkey_credentials_by_user_id(session.user.identity.id),
  )
  use credential <- program.and_then(
    credentials
    |> list.find(fn(credential) { credential.id == request.id })
    |> option.from_result()
    |> program.from_option(error.auth(auth_error.NotOwner)),
  )
  use _ <- program.and_then(
    transaction_program.sequence([
      passkey_effect.delete_passkey_credential_tx(credential.id),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )

  program.succeed(Nil)
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(DeleteAccountPasskeyRequest) {
  program.decode_dynamic(
    data,
    passkey_dto.delete_account_passkey_request_decoder(),
  )
}
