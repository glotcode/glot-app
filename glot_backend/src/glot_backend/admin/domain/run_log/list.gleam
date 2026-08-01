import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/logging/run_log/effect/effect as run_log_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/run_log_dto.{
  type ListRunLogsRequest, type ListRunLogsResponse,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/pagination_model
import glot_core/run_log_model

pub fn get_run_logs(
  request_ctx: RequestContext,
  request: ListRunLogsRequest,
) -> Program(ListRunLogsResponse) {
  let pagination = request.pagination
  use _ <- program.and_then(
    pagination_model.validate(pagination, 100)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminRunLogsAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use logs <- program.and_then(run_log_effect.list(
    run_log_dto.ListRunLogsRequest(
      ..request,
      pagination: pagination_model.increment_limit(pagination),
    ),
  ))

  let page = pagination_model.paginate(logs, pagination, run_log_model.cursor)

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(run_log_dto.from_run_logs(page))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(ListRunLogsRequest) {
  program.decode_dynamic(data, run_log_dto.list_request_decoder())
}
