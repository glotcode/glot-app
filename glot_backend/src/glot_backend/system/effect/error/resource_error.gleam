pub type ResourceError {
  UserNotFound
  JobNotFound
  SnippetNotFound
  PeriodicJobNotFound
  JobTypePolicyNotFound
  ApiLogNotFound
  RunLogNotFound
  JobLogNotFound
  EmailTemplateNotFound
  DockerRunConfigNotFound
  SpamClassifierConfigNotFound
  SnippetClassificationStale
  CloudflareConfigNotFound
  AccountDeleteNotScheduled
  AccountDeleteAlreadyScheduled
}

pub fn status(err: ResourceError) -> Int {
  case err {
    AccountDeleteNotScheduled
    | AccountDeleteAlreadyScheduled
    | SnippetClassificationStale -> 409
    _ -> 404
  }
}

pub fn code(err: ResourceError) -> String {
  case err {
    UserNotFound -> "user_not_found"
    JobNotFound -> "job_not_found"
    SnippetNotFound -> "snippet_not_found"
    PeriodicJobNotFound -> "periodic_job_not_found"
    JobTypePolicyNotFound -> "job_type_policy_not_found"
    ApiLogNotFound -> "api_log_not_found"
    RunLogNotFound -> "run_log_not_found"
    JobLogNotFound -> "job_log_not_found"
    EmailTemplateNotFound -> "email_template_not_found"
    DockerRunConfigNotFound -> "docker_run_config_not_found"
    SpamClassifierConfigNotFound -> "spam_classifier_config_not_found"
    SnippetClassificationStale -> "snippet_classification_stale"
    CloudflareConfigNotFound -> "cloudflare_config_not_found"
    AccountDeleteNotScheduled -> "account_delete_not_scheduled"
    AccountDeleteAlreadyScheduled -> "account_delete_already_scheduled"
  }
}

pub fn message(err: ResourceError) -> String {
  case err {
    UserNotFound -> "User not found"
    JobNotFound -> "Job not found"
    SnippetNotFound -> "Snippet not found"
    PeriodicJobNotFound -> "Periodic job not found"
    JobTypePolicyNotFound -> "Job type policy not found"
    ApiLogNotFound -> "API log not found"
    RunLogNotFound -> "Run log not found"
    JobLogNotFound -> "Job log not found"
    EmailTemplateNotFound -> "Email template not found"
    DockerRunConfigNotFound -> "Docker run config is not configured"
    SpamClassifierConfigNotFound -> "Spam classifier config is not configured"
    SnippetClassificationStale ->
      "Snippet changed while it was being classified; try again"
    CloudflareConfigNotFound -> "Cloudflare config is not configured"
    AccountDeleteNotScheduled -> "Account deletion is not scheduled"
    AccountDeleteAlreadyScheduled -> "Account deletion already scheduled"
  }
}

pub fn to_string(err: ResourceError) -> String {
  let prefix = case status(err) {
    404 -> "not_found:"
    _ -> "conflict:"
  }
  prefix <> code(err)
}
