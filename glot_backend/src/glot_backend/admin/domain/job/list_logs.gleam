import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/log/effect as job_log_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/job_log_dto.{
  type ListJobLogsRequest, type ListJobLogsResponse,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/job_log_model
import glot_core/pagination_model

pub fn get_job_logs(
  request_ctx: RequestContext,
  request: ListJobLogsRequest,
) -> Program(ListJobLogsResponse) {
  let pagination = request.pagination
  use _ <- program.and_then(
    pagination_model.validate(pagination, 100)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminJobLogsAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use logs <- program.and_then(job_log_effect.list(
    job_log_dto.ListJobLogsRequest(
      ..request,
      pagination: pagination_model.increment_limit(pagination),
    ),
  ))

  let page = pagination_model.paginate(logs, pagination, job_log_model.cursor)

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(job_log_dto.from_job_logs(page))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(ListJobLogsRequest) {
  program.decode_dynamic(data, job_log_dto.list_request_decoder())
}
