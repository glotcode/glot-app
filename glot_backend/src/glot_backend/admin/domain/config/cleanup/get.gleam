import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/cleanup_config_dto.{type CleanupConfigResponse}
import glot_core/admin_action
import glot_core/api_action

pub fn get_cleanup_config(
  request_ctx: RequestContext,
) -> Program(CleanupConfigResponse) {
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminCleanupConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  let cleanup_config = dynamic_config.cleanup_config(config)
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(cleanup_config_dto.CleanupConfigResponse(
    api_log_retention_days: cleanup_config.api_log_retention_days,
    page_log_retention_days: cleanup_config.page_log_retention_days,
    pageview_log_retention_days: cleanup_config.pageview_log_retention_days,
    run_log_retention_days: cleanup_config.run_log_retention_days,
    job_log_retention_days: cleanup_config.job_log_retention_days,
    jobs_retention_days: cleanup_config.jobs_retention_days,
    login_tokens_retention_days: cleanup_config.login_tokens_retention_days,
    user_actions_retention_days: cleanup_config.user_actions_retention_days,
  ))
}
