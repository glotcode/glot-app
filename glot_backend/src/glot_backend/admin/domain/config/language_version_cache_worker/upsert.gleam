import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/language_version_cache_worker_config_dto.{
  type LanguageVersionCacheWorkerConfigResponse,
  type UpsertLanguageVersionCacheWorkerConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

const max_refresh_interval_ms = 86_400_000

const max_refresh_step_delay_ms = 60_000

const max_refresh_step_jitter_ms = 60_000

const max_default_timeout_ms = 600_000

pub fn upsert_language_version_cache_worker_config(
  request_ctx: RequestContext,
  request: UpsertLanguageVersionCacheWorkerConfigRequest,
) -> Program(LanguageVersionCacheWorkerConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(
      admin_action.UpsertAdminLanguageVersionCacheWorkerConfigAction,
    ),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use _ <- program.and_then(
    app_config_effect.upsert_language_version_cache_worker_config(
      run_code_config.LanguageVersionCacheWorkerConfig(
        refresh_interval_ms: request.refresh_interval_ms,
        refresh_step_delay_ms: request.refresh_step_delay_ms,
        refresh_step_jitter_ms: request.refresh_step_jitter_ms,
        default_timeout_ms: request.default_timeout_ms,
      ),
      ctx.timestamp,
    ),
  )
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(
    language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse(
      refresh_interval_ms: request.refresh_interval_ms,
      refresh_step_delay_ms: request.refresh_step_delay_ms,
      refresh_step_jitter_ms: request.refresh_step_jitter_ms,
      default_timeout_ms: request.default_timeout_ms,
    ),
  )
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertLanguageVersionCacheWorkerConfigRequest) {
  program.decode_dynamic(
    data,
    language_version_cache_worker_config_dto.decoder(),
  )
}

fn validate_request(
  request: UpsertLanguageVersionCacheWorkerConfigRequest,
) -> Program(Nil) {
  use _ <- program.and_then(require_positive(
    request.refresh_interval_ms,
    "refresh_interval_ms",
  ))
  use _ <- program.and_then(require_positive(
    request.refresh_step_delay_ms,
    "refresh_step_delay_ms",
  ))
  use _ <- program.and_then(require_positive(
    request.default_timeout_ms,
    "default_timeout_ms",
  ))
  use _ <- program.and_then(require_non_negative(
    request.refresh_step_jitter_ms,
    "refresh_step_jitter_ms",
  ))
  use _ <- program.and_then(require_max(
    request.refresh_interval_ms,
    "refresh_interval_ms",
    max_refresh_interval_ms,
  ))
  use _ <- program.and_then(require_max(
    request.refresh_step_delay_ms,
    "refresh_step_delay_ms",
    max_refresh_step_delay_ms,
  ))
  use _ <- program.and_then(require_max(
    request.refresh_step_jitter_ms,
    "refresh_step_jitter_ms",
    max_refresh_step_jitter_ms,
  ))
  use _ <- program.and_then(require_max(
    request.default_timeout_ms,
    "default_timeout_ms",
    max_default_timeout_ms,
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

fn require_non_negative(value: Int, field: String) -> Program(Nil) {
  case value >= 0 {
    True -> program.succeed(Nil)
    False ->
      program.fail(
        error.validation(validation_error.MustBeGreaterThanOrEqual(field, 0)),
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
