import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/string
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/email/model/config as email_feature_config
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/cloudflare_config_dto.{
  type CloudflareConfigResponse, type UpsertCloudflareConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

pub fn upsert_cloudflare_config(
  request_ctx: RequestContext,
  request: UpsertCloudflareConfigRequest,
) -> Program(CloudflareConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminCloudflareConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use _ <- program.and_then(app_config_effect.upsert_cloudflare_config(
    email_feature_config.CloudflareConfig(
      account_id: request.account_id,
      api_token: request.api_token,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(cloudflare_config_dto.CloudflareConfigResponse(
    account_id: request.account_id,
    api_token: request.api_token,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertCloudflareConfigRequest) {
  program.decode_dynamic(data, cloudflare_config_dto.decoder())
}

fn validate_request(request: UpsertCloudflareConfigRequest) -> Program(Nil) {
  case string.trim(request.account_id), string.trim(request.api_token) {
    "", _ ->
      program.fail(error.validation(validation_error.EmptyField("accountId")))
    _, "" ->
      program.fail(error.validation(validation_error.EmptyField("apiToken")))
    _, _ -> program.succeed(Nil)
  }
}
