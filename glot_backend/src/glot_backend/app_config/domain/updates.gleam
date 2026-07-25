import gleam/json
import glot_backend/app_config/decoder/request_policy as request_policy_decoder
import glot_backend/app_config/model/entry.{type AppConfigEntry}
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_core/availability_mode
import glot_core/public_action.{type PublicAction}

pub fn debug(value: system_config.DebugConfig) -> List(AppConfigEntry) {
  [entry("debug", "enabled", json.bool(value.enabled))]
}

pub fn availability(
  value: request_policy_config.AvailabilityConfig,
) -> List(AppConfigEntry) {
  [
    entry("availability", "mode", availability_mode.encode(value.mode)),
    entry("availability", "message", json.string(value.message)),
    entry(
      "availability",
      "retry_after_seconds",
      json.nullable(value.retry_after_seconds, json.int),
    ),
  ]
}

pub fn auth(value: auth_feature_config.AuthConfig) -> List(AppConfigEntry) {
  [
    entry("auth", "login_token_max_age", json.int(value.login_token_max_age)),
    entry(
      "auth",
      "session_token_max_age",
      json.int(value.session_token_max_age),
    ),
    entry(
      "auth",
      "session_idle_timeout_seconds",
      json.int(value.session_idle_timeout_seconds),
    ),
    entry(
      "auth",
      "session_cookie_max_age",
      json.int(value.session_cookie_max_age),
    ),
    entry(
      "auth",
      "session_refresh_interval_seconds",
      json.int(value.session_refresh_interval_seconds),
    ),
    entry(
      "auth",
      "session_previous_token_grace_seconds",
      json.int(value.session_previous_token_grace_seconds),
    ),
    entry(
      "auth",
      "session_heartbeat_interval_seconds",
      json.int(value.session_heartbeat_interval_seconds),
    ),
  ]
}

pub fn passkey(
  value: auth_feature_config.PasskeyConfig,
) -> List(AppConfigEntry) {
  [
    entry("passkey", "origin", json.string(value.origin)),
    entry("passkey", "rp_id", json.string(value.rp_id)),
    entry(
      "passkey",
      "challenge_timeout_seconds",
      json.int(value.challenge_timeout_seconds),
    ),
  ]
}

pub fn cleanup(value: system_config.CleanupConfig) -> List(AppConfigEntry) {
  [
    entry(
      "cleanup",
      "api_log_retention_days",
      json.int(value.api_log_retention_days),
    ),
    entry(
      "cleanup",
      "page_log_retention_days",
      json.int(value.page_log_retention_days),
    ),
    entry(
      "cleanup",
      "pageview_log_retention_days",
      json.int(value.pageview_log_retention_days),
    ),
    entry(
      "cleanup",
      "run_log_retention_days",
      json.int(value.run_log_retention_days),
    ),
    entry(
      "cleanup",
      "job_log_retention_days",
      json.int(value.job_log_retention_days),
    ),
    entry("cleanup", "jobs_retention_days", json.int(value.jobs_retention_days)),
    entry(
      "cleanup",
      "login_tokens_retention_days",
      json.int(value.login_tokens_retention_days),
    ),
    entry(
      "cleanup",
      "user_actions_retention_days",
      json.int(value.user_actions_retention_days),
    ),
  ]
}

pub fn log_worker(value: logging_config.Config) -> List(AppConfigEntry) {
  [
    entry("log_worker", "flush_interval_ms", json.int(value.flush_interval_ms)),
    entry("log_worker", "max_batch_size", json.int(value.max_batch_size)),
    entry("log_worker", "max_buffer_size", json.int(value.max_buffer_size)),
  ]
}

pub fn http_pool(value: system_config.HttpPoolConfig) -> List(AppConfigEntry) {
  [
    entry(
      "http_pool",
      "docker_run_max_sessions",
      json.int(value.docker_run_max_sessions),
    ),
    entry(
      "http_pool",
      "cloudflare_email_max_sessions",
      json.int(value.cloudflare_email_max_sessions),
    ),
    entry(
      "http_pool",
      "keep_alive_timeout_ms",
      json.int(value.keep_alive_timeout_ms),
    ),
  ]
}

pub fn language_version_cache_worker(
  value: run_code_config.LanguageVersionCacheWorkerConfig,
) -> List(AppConfigEntry) {
  [
    entry(
      "language_version_cache_worker",
      "refresh_interval_ms",
      json.int(value.refresh_interval_ms),
    ),
    entry(
      "language_version_cache_worker",
      "refresh_step_delay_ms",
      json.int(value.refresh_step_delay_ms),
    ),
    entry(
      "language_version_cache_worker",
      "refresh_step_jitter_ms",
      json.int(value.refresh_step_jitter_ms),
    ),
    entry(
      "language_version_cache_worker",
      "default_timeout_ms",
      json.int(value.default_timeout_ms),
    ),
  ]
}

pub fn rate_limit(
  action: PublicAction,
  value: request_policy_config.RateLimitPolicy,
) -> List(AppConfigEntry) {
  [
    entry(
      "rate_limit",
      public_action.to_string(action),
      request_policy_decoder.encode_rate_limit_policy(value),
    ),
  ]
}

pub fn docker_run(
  value: run_code_config.DockerRunConfig,
) -> List(AppConfigEntry) {
  [
    entry("docker_run", "base_url", json.string(value.base_url)),
    entry("docker_run", "access_token", json.string(value.access_token)),
    entry(
      "docker_run",
      "default_timeout_ms",
      json.int(value.default_timeout_ms),
    ),
  ]
}

pub fn cloudflare(
  value: email_feature_config.CloudflareConfig,
) -> List(AppConfigEntry) {
  [
    entry("cloudflare", "account_id", json.string(value.account_id)),
    entry("cloudflare", "api_token", json.string(value.api_token)),
  ]
}

pub fn email(value: email_feature_config.EmailConfig) -> List(AppConfigEntry) {
  [
    entry("email", "from_address", json.string(value.from_address)),
    entry("email", "from_name", json.nullable(value.from_name, json.string)),
    entry(
      "email",
      "contact_address",
      json.nullable(value.contact_address, json.string),
    ),
    entry("email", "default_timeout_ms", json.int(value.default_timeout_ms)),
  ]
}

fn entry(namespace: String, key: String, value: json.Json) -> AppConfigEntry {
  entry.AppConfigEntry(namespace:, key:, value: json.to_string(value))
}
