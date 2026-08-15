import gleam/dict
import gleam/option
import glot_backend/app_config/model/defaults
import glot_backend/app_config/model/system_config as system_config_model
import glot_backend/auth/model/config as auth_config_model
import glot_backend/email/model/config as email_config_model
import glot_backend/logging/ingestion/model/config as logging_config_model
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config_model
import glot_backend/spam_classifier/model/config as spam_classifier_config
import glot_core/public_action.{type PublicAction}

pub type DynamicConfig {
  DynamicConfig(
    debug: system_config_model.DebugConfig,
    http_pool: system_config_model.HttpPoolConfig,
    availability: request_policy_config.AvailabilityConfig,
    auth: auth_config_model.AuthConfig,
    passkey: auth_config_model.PasskeyConfig,
    cleanup: system_config_model.CleanupConfig,
    log_worker: logging_config_model.Config,
    language_version_cache_worker: run_code_config_model.LanguageVersionCacheWorkerConfig,
    docker_run: option.Option(run_code_config_model.DockerRunConfig),
    spam_classifier: option.Option(spam_classifier_config.Config),
    cloudflare: option.Option(email_config_model.CloudflareConfig),
    email: option.Option(email_config_model.EmailConfig),
    rate_limit_policies: dict.Dict(
      PublicAction,
      request_policy_config.RateLimitPolicy,
    ),
  )
}

pub fn empty() -> DynamicConfig {
  DynamicConfig(
    debug: defaults.debug(),
    http_pool: defaults.http_pool(),
    availability: defaults.availability(),
    auth: defaults.auth(),
    passkey: defaults.passkey(),
    cleanup: defaults.cleanup(),
    log_worker: defaults.log_worker(),
    language_version_cache_worker: defaults.language_version_cache_worker(),
    docker_run: option.None,
    spam_classifier: option.None,
    cloudflare: option.None,
    email: option.None,
    rate_limit_policies: dict.new(),
  )
}

pub fn lookup_rate_limit_policy(
  config: DynamicConfig,
  action: PublicAction,
) -> option.Option(request_policy_config.RateLimitPolicy) {
  dict.get(config.rate_limit_policies, action)
  |> option.from_result()
}

pub fn docker_run_config(
  config: DynamicConfig,
) -> option.Option(run_code_config_model.DockerRunConfig) {
  config.docker_run
}

pub fn spam_classifier_config(
  config: DynamicConfig,
) -> option.Option(spam_classifier_config.Config) {
  config.spam_classifier
}

pub fn cloudflare_config(
  config: DynamicConfig,
) -> option.Option(email_config_model.CloudflareConfig) {
  config.cloudflare
}

pub fn email_config(config: DynamicConfig) -> email_config_model.EmailConfig {
  option.unwrap(config.email, defaults.email())
}

pub fn auth_config(config: DynamicConfig) -> auth_config_model.AuthConfig {
  config.auth
}

pub fn passkey_config(
  config: DynamicConfig,
) -> auth_config_model.PasskeyConfig {
  config.passkey
}

pub fn cleanup_config(
  config: DynamicConfig,
) -> system_config_model.CleanupConfig {
  config.cleanup
}

pub fn log_worker_config(config: DynamicConfig) -> logging_config_model.Config {
  config.log_worker
}

pub fn language_version_cache_worker_config(
  config: DynamicConfig,
) -> run_code_config_model.LanguageVersionCacheWorkerConfig {
  config.language_version_cache_worker
}

pub fn debug_config(config: DynamicConfig) -> system_config_model.DebugConfig {
  config.debug
}

pub fn http_pool_config(
  config: DynamicConfig,
) -> system_config_model.HttpPoolConfig {
  config.http_pool
}

pub fn availability_config(
  config: DynamicConfig,
) -> request_policy_config.AvailabilityConfig {
  config.availability
}

pub fn list_rate_limit_policies(
  config: DynamicConfig,
) -> List(#(PublicAction, request_policy_config.RateLimitPolicy)) {
  dict.to_list(config.rate_limit_policies)
}
