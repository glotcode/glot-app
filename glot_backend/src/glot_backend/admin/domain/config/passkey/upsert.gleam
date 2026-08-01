import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/string
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/passkey_config_dto.{
  type PasskeyConfigResponse, type UpsertPasskeyConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

pub fn upsert_passkey_config(
  request_ctx: RequestContext,
  request: UpsertPasskeyConfigRequest,
) -> Program(PasskeyConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminPasskeyConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  let origin = string.trim(request.origin)
  let rp_id = string.trim(request.rp_id)
  use _ <- program.and_then(app_config_effect.upsert_passkey_config(
    auth_feature_config.PasskeyConfig(
      origin: origin,
      rp_id: rp_id,
      challenge_timeout_seconds: request.challenge_timeout_seconds,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(passkey_config_dto.PasskeyConfigResponse(
    origin: origin,
    rp_id: rp_id,
    challenge_timeout_seconds: request.challenge_timeout_seconds,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertPasskeyConfigRequest) {
  program.decode_dynamic(data, passkey_config_dto.decoder())
}

fn validate_request(request: UpsertPasskeyConfigRequest) -> Program(Nil) {
  use _ <- program.and_then(require_non_empty(request.origin, "origin"))
  use _ <- program.and_then(require_non_empty(request.rp_id, "rpId"))
  use _ <- program.and_then(require_positive(
    request.challenge_timeout_seconds,
    "challenge_timeout_seconds",
  ))
  program.succeed(Nil)
}

fn require_non_empty(value: String, field: String) -> Program(Nil) {
  case string.trim(value) {
    "" -> program.fail(error.validation(validation_error.EmptyField(field)))
    _ -> program.succeed(Nil)
  }
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
