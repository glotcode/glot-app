import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/log_worker_config_dto.{type LogWorkerConfigResponse}
import glot_core/admin_action
import glot_core/api_action

pub fn get_log_worker_config(
  request_ctx: RequestContext,
) -> Program(LogWorkerConfigResponse) {
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminLogWorkerConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  let log_worker_config = dynamic_config.log_worker_config(config)
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(log_worker_config_dto.LogWorkerConfigResponse(
    flush_interval_ms: log_worker_config.flush_interval_ms,
    max_batch_size: log_worker_config.max_batch_size,
    max_buffer_size: log_worker_config.max_buffer_size,
  ))
}
