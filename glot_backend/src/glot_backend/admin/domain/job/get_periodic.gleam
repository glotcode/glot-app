import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/periodic/effect as periodic_job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/periodic_job_dto.{
  type GetPeriodicJobRequest, type GetPeriodicJobResponse,
}
import glot_core/admin_action
import glot_core/api_action

pub fn get_periodic_job(
  request_ctx: RequestContext,
  request: GetPeriodicJobRequest,
) -> Program(GetPeriodicJobResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminPeriodicJobAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use periodic_job <- program.and_then(
    periodic_job_effect.get_periodic_job_by_id(request.id)
    |> program.require(error.resource(resource_error.PeriodicJobNotFound)),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(periodic_job_dto.from_periodic_job_detail(periodic_job))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(GetPeriodicJobRequest) {
  program.decode_dynamic(data, periodic_job_dto.get_request_decoder())
}
