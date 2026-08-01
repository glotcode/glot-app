import gleam/dynamic.{type Dynamic}
import gleam/result
import gleam/string
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/user as user_effect
import glot_backend/request_policy/api_action as api_action_policy
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
import glot_core/auth/account_dto.{
  type AccountResponse, type UpdateAccountRequest,
}
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/public_action

pub fn update_account(
  request_ctx: RequestContext,
  request: UpdateAccountRequest,
) -> Program(AccountResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  let username = string.trim(request.username)

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
    action: api_action.public(public_action.UpdateAccountAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))

  use _ <- program.and_then(
    user_model.validate_username(username)
    |> result.map_error(error.validation)
    |> program.from_result,
  )

  let user =
    user_model.change_username(session.user.identity, username, ctx.timestamp)

  use _ <- program.and_then(
    transaction_program.sequence([
      user_effect.update_user_tx(user),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )

  program.succeed(
    account_dto.from_hydrated_user(user_model.HydratedUser(
      identity: user,
      account: account_model.HydratedAccount(
        identity: session.user.account.identity,
        delete_scheduled_at: session.user.account.delete_scheduled_at,
      ),
    )),
  )
}

pub fn request_from_dynamic(data: Dynamic) -> Program(UpdateAccountRequest) {
  program.decode_dynamic(data, account_dto.update_decoder())
}
