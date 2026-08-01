import gleam/list
import gleam/time/timestamp
import glot_backend/app_config/domain/retention
import glot_backend/app_config/model/system_config

pub fn each_retention_policy_uses_its_own_configuration_test() {
  let now = timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 123)
  let config = distinct_retention_config()

  [
    #(retention.ApiLog, 1),
    #(retention.PageLog, 2),
    #(retention.PageviewLog, 3),
    #(retention.RunLog, 4),
    #(retention.JobLog, 5),
    #(retention.Jobs, 6),
    #(retention.LoginTokens, 7),
    #(retention.UserActions, 8),
  ]
  |> list.each(fn(policy) {
    let #(policy, days) = policy
    assert retention.cutoff_from_config(now, config, policy)
      == timestamp.from_unix_seconds_and_nanoseconds(
        1_700_000_000 - days * 86_400,
        123,
      )
  })
}

pub fn zero_retention_uses_the_current_timestamp_as_cutoff_test() {
  let now = timestamp.from_unix_seconds_and_nanoseconds(1_700_000_000, 123)
  let config =
    system_config.CleanupConfig(
      ..distinct_retention_config(),
      run_log_retention_days: 0,
    )

  assert retention.cutoff_from_config(now, config, retention.RunLog) == now
}

fn distinct_retention_config() -> system_config.CleanupConfig {
  system_config.CleanupConfig(
    api_log_retention_days: 1,
    page_log_retention_days: 2,
    pageview_log_retention_days: 3,
    run_log_retention_days: 4,
    job_log_retention_days: 5,
    jobs_retention_days: 6,
    login_tokens_retention_days: 7,
    user_actions_retention_days: 8,
  )
}
