import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/string
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/docker_run_config_dto.{
  type DockerRunConfigResponse, type UpsertDockerRunConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

const max_default_timeout_ms = 600_000

pub fn upsert_docker_run_config(
  request_ctx: RequestContext,
  request: UpsertDockerRunConfigRequest,
) -> Program(DockerRunConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminDockerRunConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use _ <- program.and_then(app_config_effect.upsert_docker_run_config(
    run_code_config.DockerRunConfig(
      base_url: request.base_url,
      access_token: request.access_token,
      default_timeout_ms: request.default_timeout_ms,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(docker_run_config_dto.DockerRunConfigResponse(
    base_url: request.base_url,
    access_token: request.access_token,
    default_timeout_ms: request.default_timeout_ms,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertDockerRunConfigRequest) {
  program.decode_dynamic(data, docker_run_config_dto.decoder())
}

fn validate_request(request: UpsertDockerRunConfigRequest) -> Program(Nil) {
  use _ <- program.and_then(require_positive(
    request.default_timeout_ms,
    "default_timeout_ms",
  ))
  use _ <- program.and_then(require_max(
    request.default_timeout_ms,
    "default_timeout_ms",
    max_default_timeout_ms,
  ))

  case string.trim(request.base_url), string.trim(request.access_token) {
    "", _ ->
      program.fail(error.validation(validation_error.EmptyField("baseUrl")))
    _, "" ->
      program.fail(error.validation(validation_error.EmptyField("accessToken")))
    _, _ -> program.succeed(Nil)
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
