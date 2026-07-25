import gleam/option
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_config
import glot_backend/email/model/config as email_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_core/availability_mode

pub fn debug() -> system_config.DebugConfig {
  system_config.DebugConfig(enabled: False)
}

pub fn http_pool() -> system_config.HttpPoolConfig {
  system_config.HttpPoolConfig(
    docker_run_max_sessions: 16,
    cloudflare_email_max_sessions: 4,
    keep_alive_timeout_ms: 120_000,
  )
}

pub fn availability() -> request_policy_config.AvailabilityConfig {
  request_policy_config.AvailabilityConfig(
    mode: availability_mode.NormalMode,
    message: "glot.io is temporarily unavailable right now.",
    retry_after_seconds: option.None,
  )
}

pub fn auth() -> auth_config.AuthConfig {
  auth_config.AuthConfig(
    login_token_max_age: 900,
    session_token_max_age: 86_400,
    session_idle_timeout_seconds: 86_400,
    session_cookie_max_age: 86_400,
    session_refresh_interval_seconds: 300,
    session_previous_token_grace_seconds: 60,
    session_heartbeat_interval_seconds: 60,
  )
}

pub fn passkey() -> auth_config.PasskeyConfig {
  auth_config.PasskeyConfig(
    origin: "https://glot.io",
    rp_id: "glot.io",
    challenge_timeout_seconds: 120,
  )
}

pub fn cleanup() -> system_config.CleanupConfig {
  system_config.CleanupConfig(
    api_log_retention_days: 30,
    page_log_retention_days: 30,
    pageview_log_retention_days: 30,
    run_log_retention_days: 90,
    job_log_retention_days: 90,
    jobs_retention_days: 90,
    login_tokens_retention_days: 30,
    user_actions_retention_days: 90,
  )
}

pub fn log_worker() -> logging_config.Config {
  logging_config.default()
}

pub fn language_version_cache_worker() -> run_code_config.LanguageVersionCacheWorkerConfig {
  run_code_config.LanguageVersionCacheWorkerConfig(
    refresh_interval_ms: 3_600_000,
    refresh_step_delay_ms: 1000,
    refresh_step_jitter_ms: 500,
    default_timeout_ms: 60_000,
  )
}

pub fn docker_run() -> run_code_config.DockerRunConfig {
  run_code_config.DockerRunConfig(
    base_url: "",
    access_token: "",
    default_timeout_ms: 60_000,
  )
}

pub fn email() -> email_config.EmailConfig {
  email_config.EmailConfig(
    from_address: "glot@glot.io",
    from_name: option.Some("glot"),
    contact_address: option.None,
    default_timeout_ms: 60_000,
  )
}
