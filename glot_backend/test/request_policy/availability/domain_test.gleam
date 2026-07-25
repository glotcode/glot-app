import gleam/dict
import gleam/option
import gleam/uri
import glot_backend/app_config/effect/algebra as app_config_algebra
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/availability as availability_policy
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error
import glot_backend/system/effect/error/policy_error
import glot_backend/system/effect/program_types
import glot_core/admin_action
import glot_core/api_action
import glot_core/availability_mode
import glot_core/public_action
import glot_core/route

pub fn normal_mode_allows_public_write_api_test() {
  let config = availability_config(availability_mode.NormalMode)

  assert run_policy_program(
      availability_policy.enforce_api_action(
        config,
        api_action.public(public_action.CreateSnippetAction),
      ),
      config,
    )
    == Ok(Nil)
}

pub fn read_only_mode_blocks_public_write_api_test() {
  let config = availability_config(availability_mode.ReadOnlyMode)

  assert run_policy_program(
      availability_policy.enforce_api_action(
        config,
        api_action.public(public_action.CreateSnippetAction),
      ),
      config,
    )
    == Error(
      error.policy(policy_error.ReadOnlyModeBlocked(
        message: config.message,
        retry_after_seconds: config.retry_after_seconds,
      )),
    )
}

pub fn read_only_mode_allows_public_read_api_test() {
  let config = availability_config(availability_mode.ReadOnlyMode)

  assert run_policy_program(
      availability_policy.enforce_api_action(
        config,
        api_action.public(public_action.ListPublicSnippetsAction),
      ),
      config,
    )
    == Ok(Nil)
}

pub fn maintenance_mode_blocks_public_read_api_test() {
  let config = availability_config(availability_mode.MaintenanceMode)

  assert run_policy_program(
      availability_policy.enforce_api_action(
        config,
        api_action.public(public_action.ListPublicSnippetsAction),
      ),
      config,
    )
    == Error(
      error.policy(policy_error.MaintenanceModeBlocked(
        message: config.message,
        retry_after_seconds: config.retry_after_seconds,
      )),
    )
}

pub fn maintenance_mode_allows_admin_api_test() {
  let config = availability_config(availability_mode.MaintenanceMode)

  assert run_policy_program(
      availability_policy.enforce_api_action(
        config,
        api_action.admin(admin_action.GetAdminDebugConfigAction),
      ),
      config,
    )
    == Ok(Nil)
}

pub fn read_only_mode_keeps_general_pages_available_test() {
  let config = availability_config(availability_mode.ReadOnlyMode)

  assert run_policy_program(
      availability_policy.evaluate_page_route(
        config,
        route.Public(route.Snippets(
          after: option.None,
          before: option.None,
          username: option.None,
        )),
      ),
      config,
    )
    == Ok(availability_policy.AllowPage)
}

pub fn maintenance_mode_blocks_general_pages_test() {
  let config = availability_config(availability_mode.MaintenanceMode)

  assert run_policy_program(
      availability_policy.evaluate_page_route(
        config,
        route.Account(route.AccountHome),
      ),
      config,
    )
    == Ok(availability_policy.UnavailablePage(
      message: config.message,
      retry_after_seconds: config.retry_after_seconds,
    ))
}

pub fn maintenance_mode_keeps_login_admin_and_not_found_pages_available_test() {
  let config = availability_config(availability_mode.MaintenanceMode)
  let assert Ok(not_found_uri) = uri.parse("/missing")

  assert run_policy_program(
      availability_policy.evaluate_page_route(config, route.Public(route.Login)),
      config,
    )
    == Ok(availability_policy.AllowPage)
  assert run_policy_program(
      availability_policy.evaluate_page_route(
        config,
        route.Admin(route.AdminHome),
      ),
      config,
    )
    == Ok(availability_policy.AllowPage)
  assert run_policy_program(
      availability_policy.evaluate_page_route(
        config,
        route.NotFound(not_found_uri),
      ),
      config,
    )
    == Ok(availability_policy.AllowPage)
}

fn run_policy_program(
  program: program_types.Program(a),
  config: request_policy_config.AvailabilityConfig,
) -> Result(a, error.Error) {
  case program {
    program_types.Pure(value) -> Ok(value)
    program_types.Fail(err) -> Error(err)
    program_types.Impure(program_types.AppConfigEffect(effect)) ->
      run_policy_program(run_app_config_effect(effect, config), config)
    program_types.Impure(_) ->
      panic as "availability policy test encountered unexpected effect"
    program_types.Attempt(program:, on_error:) ->
      case run_policy_program(program, config) {
        Ok(value) -> Ok(value)
        Error(err) -> run_policy_program(on_error(err), config)
      }
  }
}

fn run_app_config_effect(
  effect: app_config_algebra.AppConfigEffect(program_types.Program(a)),
  config: request_policy_config.AvailabilityConfig,
) -> program_types.Program(a) {
  case effect {
    app_config_algebra.GetDynamicConfig(next:) ->
      next(
        Ok(dynamic_config.DynamicConfig(
          debug: system_config.DebugConfig(enabled: False),
          http_pool: system_config.HttpPoolConfig(16, 4, 120_000),
          availability: config,
          auth: auth_feature_config.AuthConfig(
            login_token_max_age: 900,
            session_token_max_age: 86_400,
            session_idle_timeout_seconds: 86_400,
            session_cookie_max_age: 86_400,
            session_refresh_interval_seconds: 300,
            session_previous_token_grace_seconds: 60,
            session_heartbeat_interval_seconds: 60,
          ),
          passkey: auth_feature_config.PasskeyConfig(
            origin: "https://glot.io",
            rp_id: "glot.io",
            challenge_timeout_seconds: 120,
          ),
          cleanup: system_config.CleanupConfig(
            api_log_retention_days: 30,
            page_log_retention_days: 30,
            pageview_log_retention_days: 30,
            run_log_retention_days: 90,
            job_log_retention_days: 90,
            jobs_retention_days: 90,
            login_tokens_retention_days: 30,
            user_actions_retention_days: 90,
          ),
          log_worker: logging_config.Config(
            flush_interval_ms: 5000,
            max_batch_size: 100,
            max_buffer_size: 1000,
          ),
          language_version_cache_worker: run_code_config.LanguageVersionCacheWorkerConfig(
            refresh_interval_ms: 3_600_000,
            refresh_step_delay_ms: 1000,
            refresh_step_jitter_ms: 500,
            default_timeout_ms: 60_000,
          ),
          docker_run: option.None,
          cloudflare: option.None,
          email: option.None,
          rate_limit_policies: dict.new(),
        )),
      )
    _ ->
      panic as "availability policy test encountered unexpected app_config effect"
  }
}

fn availability_config(
  mode: availability_mode.AvailabilityMode,
) -> request_policy_config.AvailabilityConfig {
  request_policy_config.AvailabilityConfig(
    mode: mode,
    message: "Scheduled platform maintenance.",
    retry_after_seconds: option.Some(600),
  )
}
