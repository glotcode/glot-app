import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import gleam/result
import gleam/string
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/account as account_effect
import glot_backend/auth/effect/user as user_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/user_dto.{type UpdateUserRequest, type UpdateUserResponse}
import glot_core/admin_action
import glot_core/api_action
import glot_core/auth/account_model.{type AccountState}
import glot_core/auth/user_model

pub fn update_user(
  request_ctx: RequestContext,
  request: UpdateUserRequest,
) -> Program(UpdateUserResponse) {
  let ctx = request_ctx.context

  let username = string.trim(request.username)
  let account_state_reason =
    normalized_account_state_reason(
      request.account_state,
      request.account_state_reason,
    )

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpdateAdminUserAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use hydrated_user <- program.and_then(
    user_effect.get_user_by_id(request.id)
    |> program.require(error.resource(resource_error.UserNotFound)),
  )
  use _ <- program.and_then(
    user_model.validate_username(username)
    |> result.map_error(error.validation)
    |> program.from_result,
  )

  let user =
    hydrated_user.identity
    |> user_model.change_username(username, ctx.timestamp)
    |> user_model.change_role(request.role, ctx.timestamp)

  let account =
    hydrated_user.account.identity
    |> account_model.change_state(
      request.account_state,
      account_state_reason,
      ctx.timestamp,
    )
    |> account_model.change_tier(request.account_tier, ctx.timestamp)

  use _ <- program.and_then(
    transaction_program.sequence([
      user_effect.update_user_username_tx(user.id, user.username, ctx.timestamp),
      user_effect.update_user_role_tx(user.id, user.role, ctx.timestamp),
      account_effect.update_account_tx(account),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )

  program.succeed(
    user_dto.from_updated_user(user_model.HydratedUser(
      identity: user,
      account: account_model.HydratedAccount(
        identity: account,
        delete_scheduled_at: hydrated_user.account.delete_scheduled_at,
      ),
    )),
  )
}

pub fn request_from_dynamic(data: Dynamic) -> Program(UpdateUserRequest) {
  program.decode_dynamic(data, user_dto.update_request_decoder())
}

fn normalized_account_state_reason(
  account_state: AccountState,
  value: Option(String),
) -> Option(String) {
  case account_state {
    account_model.Active -> option.None
    account_model.ReadOnly | account_model.Suspended ->
      value
      |> option.map(string.trim)
      |> option.then(fn(reason) {
        case reason == "" {
          True -> option.None
          False -> option.Some(reason)
        }
      })
  }
}
