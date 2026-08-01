import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/language_version_cache_worker_config_dto.{
  type LanguageVersionCacheWorkerConfigResponse,
}
import glot_core/admin_action
import glot_core/api_action

pub fn get_language_version_cache_worker_config(
  request_ctx: RequestContext,
) -> Program(LanguageVersionCacheWorkerConfigResponse) {
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(
      admin_action.GetAdminLanguageVersionCacheWorkerConfigAction,
    ),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  let worker_config =
    dynamic_config.language_version_cache_worker_config(config)
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(
    language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse(
      refresh_interval_ms: worker_config.refresh_interval_ms,
      refresh_step_delay_ms: worker_config.refresh_step_delay_ms,
      refresh_step_jitter_ms: worker_config.refresh_step_jitter_ms,
      default_timeout_ms: worker_config.default_timeout_ms,
    ),
  )
}
