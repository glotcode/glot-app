import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/periodic/effect as periodic_job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/periodic_job_dto.{type ListPeriodicJobsResponse}
import glot_core/admin_action
import glot_core/api_action

pub fn get_periodic_jobs(
  request_ctx: RequestContext,
) -> Program(ListPeriodicJobsResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminPeriodicJobsAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use periodic_jobs <- program.and_then(
    periodic_job_effect.list_periodic_jobs(),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(periodic_job_dto.from_periodic_jobs(periodic_jobs))
}
