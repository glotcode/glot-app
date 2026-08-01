import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/session as session_effect
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
import glot_core/auth/account_session_dto.{type DeleteAccountSessionRequest}
import glot_core/helpers/timestamp_helpers
import glot_core/public_action

pub fn delete_account_session(
  request_ctx: RequestContext,
  request: DeleteAccountSessionRequest,
) -> Program(Nil) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))
  let auth_config = dynamic_config.auth_config(config)
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.DeleteAccountSessionAction),
    actor: api_action_policy.KnownUser(
      user_id: session.user.identity.id,
      account_state: session.user.account.identity.account_state,
      account_tier: session.user.account.identity.account_tier,
      role: session.user.identity.role,
    ),
  ))
  use sessions <- program.and_then(session_effect.list_sessions_by_user_id(
    session.user.identity.id,
    timestamp_helpers.subtract_seconds(
      ctx.timestamp,
      auth_config.session_token_max_age,
    ),
    timestamp_helpers.subtract_seconds(
      ctx.timestamp,
      auth_config.session_idle_timeout_seconds,
    ),
  ))
  use account_session <- program.and_then(
    sessions
    |> list.find(fn(account_session) { account_session.id == request.id })
    |> option.from_result()
    |> program.from_option(error.auth(auth_error.NotOwner)),
  )
  use _ <- program.and_then(
    transaction_program.sequence([
      session_effect.delete_session_tx(account_session.id),
      user_action_effect.create_user_action_tx(user_action),
    ])
    |> transaction_effect.run(),
  )

  program.succeed(Nil)
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(DeleteAccountSessionRequest) {
  program.decode_dynamic(
    data,
    account_session_dto.delete_account_session_request_decoder(),
  )
}
