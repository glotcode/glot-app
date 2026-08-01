import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/passkey_config_dto.{type PasskeyConfigResponse}
import glot_core/admin_action
import glot_core/api_action

pub fn get_passkey_config(
  request_ctx: RequestContext,
) -> Program(PasskeyConfigResponse) {
  let config = request_ctx.dynamic_config

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminPasskeyConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))
  let passkey_config = dynamic_config.passkey_config(config)

  program.succeed(passkey_config_dto.PasskeyConfigResponse(
    origin: passkey_config.origin,
    rp_id: passkey_config.rp_id,
    challenge_timeout_seconds: passkey_config.challenge_timeout_seconds,
  ))
}
