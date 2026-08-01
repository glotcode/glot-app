import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/effect/user as user_effect
import glot_backend/auth/model/user_list_filters
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/user_dto.{type ListUsersRequest, type ListUsersResponse}
import glot_core/admin_action
import glot_core/api_action
import glot_core/pagination_model
import youid/uuid

pub fn get_users(
  request_ctx: RequestContext,
  request: ListUsersRequest,
) -> Program(ListUsersResponse) {
  let pagination = request.pagination
  use _ <- program.and_then(
    pagination_model.validate(pagination, 100)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminUsersAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use users <- program.and_then(user_effect.list_users(
    pagination_model.increment_limit(pagination),
    user_list_filters.UserListFilters(
      email: request.email,
      username: request.username,
      id: request.id,
      role: request.role,
      account_state: request.account_state,
      account_tier: request.account_tier,
    ),
  ))

  let page =
    pagination_model.paginate(users, pagination, fn(user) {
      pagination_model.from_string(uuid.to_string(user.identity.id))
    })

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(user_dto.from_users(page))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(ListUsersRequest) {
  program.decode_dynamic(data, user_dto.list_request_decoder())
}
