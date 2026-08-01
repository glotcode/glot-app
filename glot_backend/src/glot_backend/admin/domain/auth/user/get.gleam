import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/user as user_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/user_dto.{type GetUserRequest, type GetUserResponse}
import glot_core/admin_action
import glot_core/api_action

pub fn get_user(
  request_ctx: RequestContext,
  request: GetUserRequest,
) -> Program(GetUserResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminUserAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use user <- program.and_then(
    user_effect.get_user_by_id(request.id)
    |> program.require(error.resource(resource_error.UserNotFound)),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(user_dto.from_user_detail(user))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(GetUserRequest) {
  program.decode_dynamic(data, user_dto.get_request_decoder())
}
