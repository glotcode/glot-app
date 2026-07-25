import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/request/hydrated_context as request_context
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/http_pool_config_dto
import glot_core/admin_action
import glot_core/api_action

pub fn get_http_pool_config(
  request_ctx: request_context.RequestContext,
) -> program_types.Program(http_pool_config_dto.HttpPoolConfigResponse) {
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminHttpPoolConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  let config = dynamic_config.http_pool_config(request_ctx.dynamic_config)
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(http_pool_config_dto.HttpPoolConfigResponse(
    docker_run_max_sessions: config.docker_run_max_sessions,
    cloudflare_email_max_sessions: config.cloudflare_email_max_sessions,
    keep_alive_timeout_ms: config.keep_alive_timeout_ms,
  ))
}
