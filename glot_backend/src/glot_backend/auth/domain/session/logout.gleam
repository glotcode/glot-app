import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/session as session_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/public_action

pub fn logout(request_ctx: RequestContext) -> Program(Nil) {
  use session <- program.and_then(current_session.require_session(request_ctx))

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("session_id", session.identity.id),
        log.uuid("user_id", session.user.identity.id),
      ]),
    ),
  )

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.LogoutAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  transaction_program.sequence([
    session_effect.delete_session_tx(session.identity.id),
    user_action_effect.create_user_action_tx(user_action),
  ])
  |> transaction_effect.run()
}
