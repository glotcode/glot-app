import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/effect/algebra as app_config_algebra
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/auth/model/config as auth_feature_config
import glot_backend/email/model/config as email_feature_config
import glot_backend/logging/ingestion/model/config as logging_config
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/run_code/model/config as run_code_config
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/program_types
import glot_core/public_action.{type PublicAction}

pub fn get_dynamic_config_result() -> program_types.Program(
  Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
) {
  program_types.Impure(
    program_types.AppConfigEffect(app_config_algebra.GetDynamicConfig(
      next: program_types.Pure,
    )),
  )
}

pub fn get_dynamic_config() -> program_types.Program(
  dynamic_config.DynamicConfig,
) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.GetDynamicConfig(next: fn(result) {
        case result {
          Ok(config) -> program_types.Pure(config)
          Error(err) -> program_types.Fail(error.database_query_error(err))
        }
      }),
    ),
  )
}

pub fn upsert_debug_config(
  config: system_config.DebugConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertDebugConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_availability_config(
  config: request_policy_config.AvailabilityConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertAvailabilityConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_auth_config(
  config: auth_feature_config.AuthConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertAuthConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_passkey_config(
  config: auth_feature_config.PasskeyConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertPasskeyConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_cleanup_config(
  config: system_config.CleanupConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertCleanupConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_log_worker_config(
  config: logging_config.Config,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertLogWorkerConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_http_pool_config(
  config: system_config.HttpPoolConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertHttpPoolConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_language_version_cache_worker_config(
  config: run_code_config.LanguageVersionCacheWorkerConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertLanguageVersionCacheWorkerConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_rate_limit_policy(
  action: PublicAction,
  policy: request_policy_config.RateLimitPolicy,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertRateLimitPolicy(
        action: action,
        policy: policy,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_docker_run_config(
  config: run_code_config.DockerRunConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertDockerRunConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_cloudflare_config(
  config: email_feature_config.CloudflareConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertCloudflareConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}

pub fn upsert_email_config(
  config: email_feature_config.EmailConfig,
  updated_at: Timestamp,
) -> program_types.Program(dynamic_config.DynamicConfig) {
  program_types.Impure(
    program_types.AppConfigEffect(
      app_config_algebra.UpsertEmailConfig(
        config: config,
        updated_at: updated_at,
        next: fn(result) {
          case result {
            Ok(config) -> program_types.Pure(config)
            Error(err) -> program_types.Fail(err)
          }
        },
      ),
    ),
  )
}
