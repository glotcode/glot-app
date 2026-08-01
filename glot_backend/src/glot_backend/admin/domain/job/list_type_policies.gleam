import gleam/option
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/type_policy/effect as job_type_policy_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/job_type_policy_dto.{type ListJobTypePoliciesResponse}
import glot_core/admin_action
import glot_core/api_action

pub fn get_job_type_policies(
  request_ctx: RequestContext,
) -> Program(ListJobTypePoliciesResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminJobTypePoliciesAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use policies <- program.and_then(
    job_type_policy_effect.list_job_type_policies(),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(job_type_policy_dto.from_job_type_policies(policies))
}
