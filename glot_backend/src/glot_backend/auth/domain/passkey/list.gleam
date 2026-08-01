import gleam/list
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/passkey as passkey_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/auth/passkey_dto.{type ListAccountPasskeysResponse}
import glot_core/public_action

pub fn list_account_passkeys(
  request_ctx: RequestContext,
) -> Program(ListAccountPasskeysResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.ListAccountPasskeysAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))
  use credentials <- program.and_then(
    passkey_effect.list_passkey_credentials_by_user_id(session.user.identity.id),
  )

  program.succeed(
    passkey_dto.ListAccountPasskeysResponse(
      passkeys: list.map(credentials, fn(credential) {
        passkey_dto.AccountPasskeyResponse(
          id: credential.id,
          os_name: credential.os_name,
          browser_name: credential.browser_name,
          created_at: credential.created_at,
          last_used_at: credential.last_used_at,
        )
      }),
    ),
  )
}
