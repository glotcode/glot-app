import gleam/result
import glot_backend/app_config/decoder/value
import glot_backend/app_config/model/entry.{type AppConfigEntry}
import glot_backend/app_config/model/system_config.{
  type CleanupConfig, type DebugConfig, type HttpPoolConfig,
}

pub fn debug(
  current: DebugConfig,
  entry: AppConfigEntry,
) -> Result(DebugConfig, String) {
  use decoded <- result.try(value.bool("debug", entry))

  case entry.key {
    "enabled" -> Ok(system_config.DebugConfig(enabled: decoded))
    _ -> Ok(current)
  }
}

pub fn http_pool(
  current: HttpPoolConfig,
  entry: AppConfigEntry,
) -> Result(HttpPoolConfig, String) {
  use decoded <- result.try(value.int("http_pool", entry))
  use _ <- result.try(case decoded > 0 {
    True -> Ok(Nil)
    False -> Error("http_pool:" <> entry.key <> " must be greater than zero")
  })

  case entry.key {
    "docker_run_max_sessions" ->
      Ok(
        system_config.HttpPoolConfig(
          ..current,
          docker_run_max_sessions: decoded,
        ),
      )
    "cloudflare_email_max_sessions" ->
      Ok(
        system_config.HttpPoolConfig(
          ..current,
          cloudflare_email_max_sessions: decoded,
        ),
      )
    "keep_alive_timeout_ms" ->
      Ok(
        system_config.HttpPoolConfig(..current, keep_alive_timeout_ms: decoded),
      )
    _ -> Ok(current)
  }
}

pub fn cleanup(
  current: CleanupConfig,
  entry: AppConfigEntry,
) -> Result(CleanupConfig, String) {
  use decoded <- result.try(value.int("cleanup", entry))

  case entry.key {
    "api_log_retention_days" ->
      Ok(
        system_config.CleanupConfig(..current, api_log_retention_days: decoded),
      )
    "page_log_retention_days" ->
      Ok(
        system_config.CleanupConfig(..current, page_log_retention_days: decoded),
      )
    "pageview_log_retention_days" ->
      Ok(
        system_config.CleanupConfig(
          ..current,
          pageview_log_retention_days: decoded,
        ),
      )
    "run_log_retention_days" ->
      Ok(
        system_config.CleanupConfig(..current, run_log_retention_days: decoded),
      )
    "job_log_retention_days" ->
      Ok(
        system_config.CleanupConfig(..current, job_log_retention_days: decoded),
      )
    "jobs_retention_days" ->
      Ok(system_config.CleanupConfig(..current, jobs_retention_days: decoded))
    "login_tokens_retention_days" ->
      Ok(
        system_config.CleanupConfig(
          ..current,
          login_tokens_retention_days: decoded,
        ),
      )
    "user_actions_retention_days" ->
      Ok(
        system_config.CleanupConfig(
          ..current,
          user_actions_retention_days: decoded,
        ),
      )
    _ -> Ok(current)
  }
}
