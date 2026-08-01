import gleam/time/timestamp.{type Timestamp}
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config.{type CleanupConfig}
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/helpers/timestamp_helpers

pub type Policy {
  ApiLog
  PageLog
  PageviewLog
  RunLog
  JobLog
  Jobs
  LoginTokens
  UserActions
}

pub fn cutoff(now: Timestamp, policy: Policy) -> Program(Timestamp) {
  use config <- program.and_then(app_config_effect.get_dynamic_config())
  program.succeed(cutoff_from_config(
    now,
    dynamic_config.cleanup_config(config),
    policy,
  ))
}

pub fn cutoff_from_config(
  now: Timestamp,
  config: CleanupConfig,
  policy: Policy,
) -> Timestamp {
  timestamp_helpers.days_ago(now, retention_days(config, policy))
}

fn retention_days(config: CleanupConfig, policy: Policy) -> Int {
  case policy {
    ApiLog -> config.api_log_retention_days
    PageLog -> config.page_log_retention_days
    PageviewLog -> config.pageview_log_retention_days
    RunLog -> config.run_log_retention_days
    JobLog -> config.job_log_retention_days
    Jobs -> config.jobs_retention_days
    LoginTokens -> config.login_tokens_retention_days
    UserActions -> config.user_actions_retention_days
  }
}
