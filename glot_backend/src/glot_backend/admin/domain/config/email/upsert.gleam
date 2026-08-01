import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import gleam/string
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/email/model/config as email_feature_config
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/context.{type Context}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/email_config_dto.{
  type EmailConfigResponse, type UpsertEmailConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/email/email_address_model
import glot_core/validation_error

const max_default_timeout_ms = 600_000

pub fn upsert_email_config(
  request_ctx: RequestContext,
  request: UpsertEmailConfigRequest,
) -> Program(EmailConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminEmailConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(ctx, request))
  let from_name = normalize_from_name(request.from_name)
  let contact_address = normalize_optional_string(request.contact_address)
  use _ <- program.and_then(app_config_effect.upsert_email_config(
    email_feature_config.EmailConfig(
      from_address: request.from_address,
      from_name: from_name,
      contact_address: contact_address,
      default_timeout_ms: request.default_timeout_ms,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(email_config_dto.EmailConfigResponse(
    from_address: request.from_address,
    from_name: from_name,
    contact_address: contact_address,
    default_timeout_ms: request.default_timeout_ms,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertEmailConfigRequest) {
  program.decode_dynamic(data, email_config_dto.decoder())
}

fn validate_request(
  ctx: Context,
  request: UpsertEmailConfigRequest,
) -> Program(Nil) {
  use _ <- program.and_then(require_positive(
    request.default_timeout_ms,
    "default_timeout_ms",
  ))
  use _ <- program.and_then(require_max(
    request.default_timeout_ms,
    "default_timeout_ms",
    max_default_timeout_ms,
  ))

  use _ <- program.and_then(validate_optional_email(
    ctx,
    request.contact_address,
    "contactAddress",
  ))

  case string.trim(request.from_address) {
    "" ->
      program.fail(error.validation(validation_error.EmptyField("fromAddress")))
    _ ->
      case
        email_address_model.from_string(
          ctx.regexes.is_email,
          request.from_address,
        )
      {
        option.Some(_) -> program.succeed(Nil)
        option.None ->
          program.fail(
            error.validation(validation_error.InvalidEmail("fromAddress")),
          )
      }
  }
}

fn validate_optional_email(
  ctx: Context,
  value: Option(String),
  field: String,
) -> Program(Nil) {
  case normalize_optional_string(value) {
    option.None -> program.succeed(Nil)
    option.Some(address) ->
      case email_address_model.from_string(ctx.regexes.is_email, address) {
        option.Some(_) -> program.succeed(Nil)
        option.None ->
          program.fail(error.validation(validation_error.InvalidEmail(field)))
      }
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

fn require_max(value: Int, field: String, max: Int) -> Program(Nil) {
  case value <= max {
    True -> program.succeed(Nil)
    False ->
      program.fail(
        error.validation(validation_error.MustBeLessThanOrEqual(field, max)),
      )
  }
}

fn normalize_from_name(value: Option(String)) -> Option(String) {
  normalize_optional_string(value)
}

fn normalize_optional_string(value: Option(String)) -> Option(String) {
  case value {
    option.Some(name) ->
      case string.trim(name) {
        "" -> option.None
        trimmed -> option.Some(trimmed)
      }
    option.None -> option.None
  }
}
