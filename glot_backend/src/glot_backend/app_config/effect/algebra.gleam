import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_core/public_action.{type PublicAction}

pub type AppConfigEffect(next) {
  GetDynamicConfig(
    next: fn(Result(dynamic_config.DynamicConfig, db_error.DbQueryError)) ->
      next,
  )
  UpsertDebugConfig(
    config: system_config.DebugConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertAvailabilityConfig(
    config: request_policy_config.AvailabilityConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertAuthConfig(
    config: auth_feature_config.AuthConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertPasskeyConfig(
    config: auth_feature_config.PasskeyConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertCleanupConfig(
    config: system_config.CleanupConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertLogWorkerConfig(
    config: logging_config.Config,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertHttpPoolConfig(
    config: system_config.HttpPoolConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertLanguageVersionCacheWorkerConfig(
    config: run_code_config.LanguageVersionCacheWorkerConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertRateLimitPolicy(
    action: PublicAction,
    policy: request_policy_config.RateLimitPolicy,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertDockerRunConfig(
    config: run_code_config.DockerRunConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertCloudflareConfig(
    config: email_feature_config.CloudflareConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
  UpsertEmailConfig(
    config: email_feature_config.EmailConfig,
    updated_at: Timestamp,
    next: fn(Result(dynamic_config.DynamicConfig, error.Error)) -> next,
  )
}

pub fn map(effect: AppConfigEffect(a), f: fn(a) -> b) -> AppConfigEffect(b) {
  case effect {
    GetDynamicConfig(next:) ->
      GetDynamicConfig(next: fn(value) { f(next(value)) })
    UpsertDebugConfig(config:, updated_at:, next:) ->
      UpsertDebugConfig(config: config, updated_at: updated_at, next: fn(value) {
        f(next(value))
      })
    UpsertAvailabilityConfig(config:, updated_at:, next:) ->
      UpsertAvailabilityConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertAuthConfig(config:, updated_at:, next:) ->
      UpsertAuthConfig(config: config, updated_at: updated_at, next: fn(value) {
        f(next(value))
      })
    UpsertPasskeyConfig(config:, updated_at:, next:) ->
      UpsertPasskeyConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertCleanupConfig(config:, updated_at:, next:) ->
      UpsertCleanupConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertLogWorkerConfig(config:, updated_at:, next:) ->
      UpsertLogWorkerConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertHttpPoolConfig(config:, updated_at:, next:) ->
      UpsertHttpPoolConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertLanguageVersionCacheWorkerConfig(config:, updated_at:, next:) ->
      UpsertLanguageVersionCacheWorkerConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertRateLimitPolicy(action:, policy:, updated_at:, next:) ->
      UpsertRateLimitPolicy(
        action: action,
        policy: policy,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertDockerRunConfig(config:, updated_at:, next:) ->
      UpsertDockerRunConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertCloudflareConfig(config:, updated_at:, next:) ->
      UpsertCloudflareConfig(
        config: config,
        updated_at: updated_at,
        next: fn(value) { f(next(value)) },
      )
    UpsertEmailConfig(config:, updated_at:, next:) ->
      UpsertEmailConfig(config: config, updated_at: updated_at, next: fn(value) {
        f(next(value))
      })
  }
}

pub type EffectName {
  GetDynamicConfigEffectName
  UpsertDebugConfigEffectName
  UpsertAvailabilityConfigEffectName
  UpsertAuthConfigEffectName
  UpsertPasskeyConfigEffectName
  UpsertCleanupConfigEffectName
  UpsertLogWorkerConfigEffectName
  UpsertHttpPoolConfigEffectName
  UpsertLanguageVersionCacheWorkerConfigEffectName
  UpsertRateLimitPolicyEffectName
  UpsertDockerRunConfigEffectName
  UpsertCloudflareConfigEffectName
  UpsertEmailConfigEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    GetDynamicConfigEffectName -> "get_dynamic_config"
    UpsertDebugConfigEffectName -> "upsert_debug_config"
    UpsertAvailabilityConfigEffectName -> "upsert_availability_config"
    UpsertAuthConfigEffectName -> "upsert_auth_config"
    UpsertPasskeyConfigEffectName -> "upsert_passkey_config"
    UpsertCleanupConfigEffectName -> "upsert_cleanup_config"
    UpsertLogWorkerConfigEffectName -> "upsert_log_worker_config"
    UpsertHttpPoolConfigEffectName -> "upsert_http_pool_config"
    UpsertLanguageVersionCacheWorkerConfigEffectName ->
      "upsert_language_version_cache_worker_config"
    UpsertRateLimitPolicyEffectName -> "upsert_rate_limit_policy"
    UpsertDockerRunConfigEffectName -> "upsert_docker_run_config"
    UpsertCloudflareConfigEffectName -> "upsert_cloudflare_config"
    UpsertEmailConfigEffectName -> "upsert_email_config"
  }
}
