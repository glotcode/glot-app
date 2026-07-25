pub type DebugConfig {
  DebugConfig(enabled: Bool)
}

pub type HttpPoolConfig {
  HttpPoolConfig(
    docker_run_max_sessions: Int,
    cloudflare_email_max_sessions: Int,
    keep_alive_timeout_ms: Int,
  )
}

pub type CleanupConfig {
  CleanupConfig(
    api_log_retention_days: Int,
    page_log_retention_days: Int,
    pageview_log_retention_days: Int,
    run_log_retention_days: Int,
    job_log_retention_days: Int,
    jobs_retention_days: Int,
    login_tokens_retention_days: Int,
    user_actions_retention_days: Int,
  )
}
