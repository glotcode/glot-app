import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/effect/session as session_effect
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_core/helpers/timestamp_helpers

pub fn clean_sessions(ctx: Context) -> Program(Nil) {
  use config <- program.and_then(app_config_effect.get_dynamic_config())
  let auth_config = dynamic_config.auth_config(config)
  let created_before =
    timestamp_helpers.subtract_seconds(
      ctx.timestamp,
      auth_config.session_token_max_age,
    )
  let token_updated_before =
    timestamp_helpers.subtract_seconds(
      ctx.timestamp,
      auth_config.session_idle_timeout_seconds,
    )
  session_effect.delete_expired_sessions(created_before, token_updated_before)
}
