import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/auth_config_dto.{
  type AuthConfigResponse, type UpsertAuthConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

pub fn upsert_auth_config(
  request_ctx: RequestContext,
  request: UpsertAuthConfigRequest,
) -> Program(AuthConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminAuthConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use _ <- program.and_then(app_config_effect.upsert_auth_config(
    auth_feature_config.AuthConfig(
      login_token_max_age: request.login_token_max_age,
      session_token_max_age: request.session_token_max_age,
      session_idle_timeout_seconds: request.session_idle_timeout_seconds,
      session_cookie_max_age: request.session_cookie_max_age,
      session_refresh_interval_seconds: request.session_refresh_interval_seconds,
      session_previous_token_grace_seconds: request.session_previous_token_grace_seconds,
      session_heartbeat_interval_seconds: request.session_heartbeat_interval_seconds,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(auth_config_dto.AuthConfigResponse(
    login_token_max_age: request.login_token_max_age,
    session_token_max_age: request.session_token_max_age,
    session_idle_timeout_seconds: request.session_idle_timeout_seconds,
    session_cookie_max_age: request.session_cookie_max_age,
    session_refresh_interval_seconds: request.session_refresh_interval_seconds,
    session_previous_token_grace_seconds: request.session_previous_token_grace_seconds,
    session_heartbeat_interval_seconds: request.session_heartbeat_interval_seconds,
  ))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(UpsertAuthConfigRequest) {
  program.decode_dynamic(data, auth_config_dto.decoder())
}

fn validate_request(request: UpsertAuthConfigRequest) -> Program(Nil) {
  use _ <- program.and_then(require_positive(
    request.login_token_max_age,
    "login_token_max_age",
  ))
  use _ <- program.and_then(require_positive(
    request.session_token_max_age,
    "session_token_max_age",
  ))
  use _ <- program.and_then(require_positive(
    request.session_idle_timeout_seconds,
    "session_idle_timeout_seconds",
  ))
  use _ <- program.and_then(require_positive(
    request.session_cookie_max_age,
    "session_cookie_max_age",
  ))
  use _ <- program.and_then(require_positive(
    request.session_refresh_interval_seconds,
    "session_refresh_interval_seconds",
  ))
  use _ <- program.and_then(require_positive(
    request.session_previous_token_grace_seconds,
    "session_previous_token_grace_seconds",
  ))
  use _ <- program.and_then(require_positive(
    request.session_heartbeat_interval_seconds,
    "session_heartbeat_interval_seconds",
  ))
  use _ <- program.and_then(require_at_least(
    request.session_idle_timeout_seconds,
    request.session_heartbeat_interval_seconds,
    "session_idle_timeout_seconds",
    "session_heartbeat_interval_seconds",
  ))

  program.succeed(Nil)
}

fn require_positive(value: Int, field: String) -> Program(Nil) {
  case value > 0 {
    True -> program.succeed(Nil)
    False ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThan(field, 0)),
      )
  }
}

fn require_at_least(
  value: Int,
  minimum: Int,
  field: String,
  minimum_field: String,
) -> Program(Nil) {
  case value >= minimum {
    True -> program.succeed(Nil)
    False ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThanOrEqualField(
          field,
          minimum_field,
        )),
      )
  }
}
