import gleam/option
import glot_backend/app_config/decoder/config as config_decoder
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/entry as app_config
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/spam_classifier/model/config as spam_classifier_config

pub fn app_config_decodes_spam_classifier_config_test() {
  let assert Ok(config) =
    config_decoder.from_entries([
      app_config.AppConfigEntry(
        namespace: "spam_classifier",
        key: "base_url",
        value: "\"http://classifier:8081\"",
      ),
      app_config.AppConfigEntry(
        namespace: "spam_classifier",
        key: "auth_token",
        value: "\"secret\"",
      ),
    ])
  assert dynamic_config.spam_classifier_config(config)
    == option.Some(spam_classifier_config.Config(
      base_url: "http://classifier:8081",
      auth_token: "secret",
    ))
}

pub fn app_config_decodes_docker_run_config_test() {
  let assert Ok(config) =
    config_decoder.from_entries([
      app_config.AppConfigEntry(
        namespace: "docker_run",
        key: "base_url",
        value: "\"https://docker-run.internal\"",
      ),
      app_config.AppConfigEntry(
        namespace: "docker_run",
        key: "access_token",
        value: "\"plain-token\"",
      ),
      app_config.AppConfigEntry(
        namespace: "docker_run",
        key: "default_timeout_ms",
        value: "45000",
      ),
    ])

  assert dynamic_config.docker_run_config(config)
    == option.Some(run_code_config.DockerRunConfig(
      base_url: "https://docker-run.internal",
      access_token: "plain-token",
      default_timeout_ms: 45_000,
    ))
}

pub fn app_config_decodes_cloudflare_config_test() {
  let assert Ok(config) =
    config_decoder.from_entries([
      app_config.AppConfigEntry(
        namespace: "cloudflare",
        key: "account_id",
        value: "\"cf-account-id\"",
      ),
      app_config.AppConfigEntry(
        namespace: "cloudflare",
        key: "api_token",
        value: "\"cf-api-token\"",
      ),
    ])

  assert dynamic_config.cloudflare_config(config)
    == option.Some(email_feature_config.CloudflareConfig(
      account_id: "cf-account-id",
      api_token: "cf-api-token",
    ))
}

pub fn app_config_decodes_email_config_test() {
  let assert Ok(config) =
    config_decoder.from_entries([
      app_config.AppConfigEntry(
        namespace: "email",
        key: "from_address",
        value: "\"sender@example.com\"",
      ),
      app_config.AppConfigEntry(
        namespace: "email",
        key: "from_name",
        value: "\"Sender\"",
      ),
      app_config.AppConfigEntry(
        namespace: "email",
        key: "contact_address",
        value: "\"contact@example.com\"",
      ),
      app_config.AppConfigEntry(
        namespace: "email",
        key: "default_timeout_ms",
        value: "45000",
      ),
    ])

  assert dynamic_config.email_config(config)
    == email_feature_config.EmailConfig(
      from_address: "sender@example.com",
      from_name: option.Some("Sender"),
      contact_address: option.Some("contact@example.com"),
      default_timeout_ms: 45_000,
    )
}

pub fn app_config_uses_default_email_config_test() {
  let assert Ok(config) = config_decoder.from_entries([])

  assert dynamic_config.email_config(config)
    == email_feature_config.EmailConfig(
      from_address: "glot@glot.io",
      from_name: option.Some("glot"),
      contact_address: option.None,
      default_timeout_ms: 60_000,
    )
}

pub fn app_config_uses_default_auth_config_test() {
  let assert Ok(config) = config_decoder.from_entries([])

  assert dynamic_config.auth_config(config)
    == auth_feature_config.AuthConfig(
      login_token_max_age: 900,
      session_token_max_age: 86_400,
      session_idle_timeout_seconds: 86_400,
      session_cookie_max_age: 86_400,
      session_refresh_interval_seconds: 300,
      session_previous_token_grace_seconds: 60,
      session_heartbeat_interval_seconds: 60,
    )
}

pub fn app_config_uses_default_debug_config_test() {
  let assert Ok(config) = config_decoder.from_entries([])

  assert dynamic_config.debug_config(config)
    == system_config.DebugConfig(enabled: False)
}

pub fn app_config_decodes_http_pool_config_test() {
  let assert Ok(config) =
    config_decoder.from_entries([
      app_config.AppConfigEntry(
        namespace: "http_pool",
        key: "docker_run_max_sessions",
        value: "24",
      ),
      app_config.AppConfigEntry(
        namespace: "http_pool",
        key: "cloudflare_email_max_sessions",
        value: "6",
      ),
      app_config.AppConfigEntry(
        namespace: "http_pool",
        key: "keep_alive_timeout_ms",
        value: "90000",
      ),
    ])

  assert dynamic_config.http_pool_config(config)
    == system_config.HttpPoolConfig(
      docker_run_max_sessions: 24,
      cloudflare_email_max_sessions: 6,
      keep_alive_timeout_ms: 90_000,
    )
}

pub fn app_config_uses_default_http_pool_config_test() {
  let assert Ok(config) = config_decoder.from_entries([])

  assert dynamic_config.http_pool_config(config)
    == system_config.HttpPoolConfig(
      docker_run_max_sessions: 16,
      cloudflare_email_max_sessions: 4,
      keep_alive_timeout_ms: 120_000,
    )
}

pub fn app_config_rejects_non_positive_http_pool_config_test() {
  assert config_decoder.from_entries([
      app_config.AppConfigEntry(
        namespace: "http_pool",
        key: "docker_run_max_sessions",
        value: "0",
      ),
    ])
    == Error("http_pool:docker_run_max_sessions must be greater than zero")
}
