import gleam/dynamic.{type Dynamic}
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/system_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/cleanup_config_dto.{
  type CleanupConfigResponse, type UpsertCleanupConfigRequest,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/validation_error

pub fn upsert_cleanup_config(
  request_ctx: RequestContext,
  request: UpsertCleanupConfigRequest,
) -> Program(CleanupConfigResponse) {
  let ctx = request_ctx.context

  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.UpsertAdminCleanupConfigAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))
  use _ <- program.and_then(validate_request(request))
  use _ <- program.and_then(app_config_effect.upsert_cleanup_config(
    system_config.CleanupConfig(
      api_log_retention_days: request.api_log_retention_days,
      page_log_retention_days: request.page_log_retention_days,
      pageview_log_retention_days: request.pageview_log_retention_days,
      run_log_retention_days: request.run_log_retention_days,
      job_log_retention_days: request.job_log_retention_days,
      jobs_retention_days: request.jobs_retention_days,
      login_tokens_retention_days: request.login_tokens_retention_days,
      user_actions_retention_days: request.user_actions_retention_days,
    ),
    ctx.timestamp,
  ))
  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(cleanup_config_dto.CleanupConfigResponse(
    api_log_retention_days: request.api_log_retention_days,
    page_log_retention_days: request.page_log_retention_days,
    pageview_log_retention_days: request.pageview_log_retention_days,
    run_log_retention_days: request.run_log_retention_days,
    job_log_retention_days: request.job_log_retention_days,
    jobs_retention_days: request.jobs_retention_days,
    login_tokens_retention_days: request.login_tokens_retention_days,
    user_actions_retention_days: request.user_actions_retention_days,
  ))
}

pub fn request_from_dynamic(
  data: Dynamic,
) -> Program(UpsertCleanupConfigRequest) {
  program.decode_dynamic(data, cleanup_config_dto.decoder())
}

fn validate_request(request: UpsertCleanupConfigRequest) -> Program(Nil) {
  use _ <- program.and_then(require_positive(
    request.api_log_retention_days,
    "api_log_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.page_log_retention_days,
    "page_log_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.pageview_log_retention_days,
    "pageview_log_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.run_log_retention_days,
    "run_log_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.job_log_retention_days,
    "job_log_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.jobs_retention_days,
    "jobs_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.login_tokens_retention_days,
    "login_tokens_retention_days",
  ))
  use _ <- program.and_then(require_positive(
    request.user_actions_retention_days,
    "user_actions_retention_days",
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
