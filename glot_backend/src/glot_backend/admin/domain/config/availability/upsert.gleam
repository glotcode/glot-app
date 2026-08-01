import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/availability_config_dto.{
  type AvailabilityConfigResponse, type UpsertAvailabilityConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action

pub fn upsert_availability_config(
  request_ctx: RequestContext,
  request: UpsertAvailabilityConfigRequest,
) -> Program(AvailabilityConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminAvailabilityConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(app_config_effect.upsert_availability_config(
    request_policy_config.AvailabilityConfig(
      mode: request.mode,
      message: request.message,
      retry_after_seconds: request.retry_after_seconds,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(availability_config_dto.AvailabilityConfigResponse(
    mode: request.mode,
    message: request.message,
    retry_after_seconds: request.retry_after_seconds,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertAvailabilityConfigRequest) {
  program.decode_dynamic(data, availability_config_dto.decoder())
}
