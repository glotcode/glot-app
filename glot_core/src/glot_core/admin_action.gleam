import gleam/dynamic/decode
import gleam/json
import gleam/option
import glot_core/server_timing_policy

pub type AdminAction {
  GetAdminAnalyticsAction
  GetAdminDebugConfigAction
  UpsertAdminDebugConfigAction
  GetAdminAvailabilityConfigAction
  UpsertAdminAvailabilityConfigAction
  GetAdminAuthConfigAction
  UpsertAdminAuthConfigAction
  GetAdminPasskeyConfigAction
  UpsertAdminPasskeyConfigAction
  GetAdminCleanupConfigAction
  UpsertAdminCleanupConfigAction
  GetAdminLogWorkerConfigAction
  UpsertAdminLogWorkerConfigAction
  GetAdminHttpPoolConfigAction
  UpsertAdminHttpPoolConfigAction
  GetAdminLanguageVersionCacheWorkerConfigAction
  UpsertAdminLanguageVersionCacheWorkerConfigAction
  GetAdminPeriodicJobsAction
  GetAdminPeriodicJobAction
  UpdateAdminPeriodicJobAction
  GetAdminJobsAction
  GetAdminJobAction
  CreateAdminJobAction
  GetAdminEmailTemplatesAction
  GetAdminEmailTemplateAction
  UpdateAdminEmailTemplateAction
  GetAdminSnippetsAction
  GetAdminSnippetAction
  DeleteAdminSnippetAction
  GetAdminUsersAction
  GetAdminUserAction
  UpdateAdminUserAction
  DeleteAdminAccountAction
  GetAdminApiLogsAction
  GetAdminApiLogAction
  GetAdminRunLogsAction
  GetAdminRunLogAction
  GetAdminJobLogsAction
  GetAdminJobLogAction
  GetAdminRateLimitPoliciesAction
  UpsertAdminRateLimitPolicyAction
  GetAdminJobTypePoliciesAction
  UpsertAdminJobTypePolicyAction
  GetAdminDockerRunConfigAction
  UpsertAdminDockerRunConfigAction
  GetAdminSpamClassifierConfigAction
  UpsertAdminSpamClassifierConfigAction
  GetAdminCloudflareConfigAction
  UpsertAdminCloudflareConfigAction
  GetAdminEmailConfigAction
  UpsertAdminEmailConfigAction
}

pub fn list() -> List(AdminAction) {
  [
    GetAdminAnalyticsAction,
    GetAdminDebugConfigAction,
    UpsertAdminDebugConfigAction,
    GetAdminAvailabilityConfigAction,
    UpsertAdminAvailabilityConfigAction,
    GetAdminAuthConfigAction,
    UpsertAdminAuthConfigAction,
    GetAdminPasskeyConfigAction,
    UpsertAdminPasskeyConfigAction,
    GetAdminCleanupConfigAction,
    UpsertAdminCleanupConfigAction,
    GetAdminLogWorkerConfigAction,
    UpsertAdminLogWorkerConfigAction,
    GetAdminHttpPoolConfigAction,
    UpsertAdminHttpPoolConfigAction,
    GetAdminLanguageVersionCacheWorkerConfigAction,
    UpsertAdminLanguageVersionCacheWorkerConfigAction,
    GetAdminPeriodicJobsAction,
    GetAdminPeriodicJobAction,
    UpdateAdminPeriodicJobAction,
    GetAdminJobsAction,
    GetAdminJobAction,
    CreateAdminJobAction,
    GetAdminEmailTemplatesAction,
    GetAdminEmailTemplateAction,
    UpdateAdminEmailTemplateAction,
    GetAdminSnippetsAction,
    GetAdminSnippetAction,
    DeleteAdminSnippetAction,
    GetAdminUsersAction,
    GetAdminUserAction,
    UpdateAdminUserAction,
    DeleteAdminAccountAction,
    GetAdminApiLogsAction,
    GetAdminApiLogAction,
    GetAdminRunLogsAction,
    GetAdminRunLogAction,
    GetAdminJobLogsAction,
    GetAdminJobLogAction,
    GetAdminRateLimitPoliciesAction,
    UpsertAdminRateLimitPolicyAction,
    GetAdminJobTypePoliciesAction,
    UpsertAdminJobTypePolicyAction,
    GetAdminDockerRunConfigAction,
    UpsertAdminDockerRunConfigAction,
    GetAdminSpamClassifierConfigAction,
    UpsertAdminSpamClassifierConfigAction,
    GetAdminCloudflareConfigAction,
    UpsertAdminCloudflareConfigAction,
    GetAdminEmailConfigAction,
    UpsertAdminEmailConfigAction,
  ]
}

pub fn decoder() -> decode.Decoder(AdminAction) {
  use action <- decode.then(decode.string)
  case from_string(action) {
    option.Some(action) -> decode.success(action)
    option.None ->
      decode.failure(GetAdminRateLimitPoliciesAction, "AdminAction")
  }
}

pub fn encode(action: AdminAction) -> json.Json {
  action |> to_string |> json.string
}

pub fn to_string(action: AdminAction) -> String {
  case action {
    GetAdminAnalyticsAction -> "get_admin_analytics"
    GetAdminDebugConfigAction -> "get_admin_debug_config"
    UpsertAdminDebugConfigAction -> "upsert_admin_debug_config"
    GetAdminAvailabilityConfigAction -> "get_admin_availability_config"
    UpsertAdminAvailabilityConfigAction -> "upsert_admin_availability_config"
    GetAdminAuthConfigAction -> "get_admin_auth_config"
    UpsertAdminAuthConfigAction -> "upsert_admin_auth_config"
    GetAdminPasskeyConfigAction -> "get_admin_passkey_config"
    UpsertAdminPasskeyConfigAction -> "upsert_admin_passkey_config"
    GetAdminCleanupConfigAction -> "get_admin_cleanup_config"
    UpsertAdminCleanupConfigAction -> "upsert_admin_cleanup_config"
    GetAdminLogWorkerConfigAction -> "get_admin_log_worker_config"
    UpsertAdminLogWorkerConfigAction -> "upsert_admin_log_worker_config"
    GetAdminHttpPoolConfigAction -> "get_admin_http_pool_config"
    UpsertAdminHttpPoolConfigAction -> "upsert_admin_http_pool_config"
    GetAdminLanguageVersionCacheWorkerConfigAction ->
      "get_admin_language_version_cache_worker_config"
    UpsertAdminLanguageVersionCacheWorkerConfigAction ->
      "upsert_admin_language_version_cache_worker_config"
    GetAdminPeriodicJobsAction -> "get_admin_periodic_jobs"
    GetAdminPeriodicJobAction -> "get_admin_periodic_job"
    UpdateAdminPeriodicJobAction -> "update_admin_periodic_job"
    GetAdminJobsAction -> "get_admin_jobs"
    GetAdminJobAction -> "get_admin_job"
    CreateAdminJobAction -> "create_admin_job"
    GetAdminEmailTemplatesAction -> "get_admin_email_templates"
    GetAdminEmailTemplateAction -> "get_admin_email_template"
    UpdateAdminEmailTemplateAction -> "update_admin_email_template"
    GetAdminSnippetsAction -> "get_admin_snippets"
    GetAdminSnippetAction -> "get_admin_snippet"
    DeleteAdminSnippetAction -> "delete_admin_snippet"
    GetAdminUsersAction -> "get_admin_users"
    GetAdminUserAction -> "get_admin_user"
    UpdateAdminUserAction -> "update_admin_user"
    DeleteAdminAccountAction -> "delete_admin_account"
    GetAdminApiLogsAction -> "get_admin_api_logs"
    GetAdminApiLogAction -> "get_admin_api_log"
    GetAdminRunLogsAction -> "get_admin_run_logs"
    GetAdminRunLogAction -> "get_admin_run_log"
    GetAdminJobLogsAction -> "get_admin_job_logs"
    GetAdminJobLogAction -> "get_admin_job_log"
    GetAdminRateLimitPoliciesAction -> "get_admin_rate_limit_policies"
    UpsertAdminRateLimitPolicyAction -> "upsert_admin_rate_limit_policy"
    GetAdminJobTypePoliciesAction -> "get_admin_job_type_policies"
    UpsertAdminJobTypePolicyAction -> "upsert_admin_job_type_policy"
    GetAdminDockerRunConfigAction -> "get_admin_docker_run_config"
    UpsertAdminDockerRunConfigAction -> "upsert_admin_docker_run_config"
    GetAdminSpamClassifierConfigAction -> "get_admin_spam_classifier_config"
    UpsertAdminSpamClassifierConfigAction ->
      "upsert_admin_spam_classifier_config"
    GetAdminCloudflareConfigAction -> "get_admin_cloudflare_config"
    UpsertAdminCloudflareConfigAction -> "upsert_admin_cloudflare_config"
    GetAdminEmailConfigAction -> "get_admin_email_config"
    UpsertAdminEmailConfigAction -> "upsert_admin_email_config"
  }
}

pub fn from_string(action: String) -> option.Option(AdminAction) {
  case action {
    "get_admin_analytics" -> option.Some(GetAdminAnalyticsAction)
    "get_admin_debug_config" -> option.Some(GetAdminDebugConfigAction)
    "upsert_admin_debug_config" -> option.Some(UpsertAdminDebugConfigAction)
    "get_admin_availability_config" ->
      option.Some(GetAdminAvailabilityConfigAction)
    "upsert_admin_availability_config" ->
      option.Some(UpsertAdminAvailabilityConfigAction)
    "get_admin_auth_config" -> option.Some(GetAdminAuthConfigAction)
    "upsert_admin_auth_config" -> option.Some(UpsertAdminAuthConfigAction)
    "get_admin_passkey_config" -> option.Some(GetAdminPasskeyConfigAction)
    "upsert_admin_passkey_config" -> option.Some(UpsertAdminPasskeyConfigAction)
    "get_admin_cleanup_config" -> option.Some(GetAdminCleanupConfigAction)
    "upsert_admin_cleanup_config" -> option.Some(UpsertAdminCleanupConfigAction)
    "get_admin_log_worker_config" -> option.Some(GetAdminLogWorkerConfigAction)
    "upsert_admin_log_worker_config" ->
      option.Some(UpsertAdminLogWorkerConfigAction)
    "get_admin_http_pool_config" -> option.Some(GetAdminHttpPoolConfigAction)
    "upsert_admin_http_pool_config" ->
      option.Some(UpsertAdminHttpPoolConfigAction)
    "get_admin_language_version_cache_worker_config" ->
      option.Some(GetAdminLanguageVersionCacheWorkerConfigAction)
    "upsert_admin_language_version_cache_worker_config" ->
      option.Some(UpsertAdminLanguageVersionCacheWorkerConfigAction)
    "get_admin_periodic_jobs" -> option.Some(GetAdminPeriodicJobsAction)
    "get_admin_periodic_job" -> option.Some(GetAdminPeriodicJobAction)
    "update_admin_periodic_job" -> option.Some(UpdateAdminPeriodicJobAction)
    "get_admin_jobs" -> option.Some(GetAdminJobsAction)
    "get_admin_job" -> option.Some(GetAdminJobAction)
    "create_admin_job" -> option.Some(CreateAdminJobAction)
    "get_admin_email_templates" -> option.Some(GetAdminEmailTemplatesAction)
    "get_admin_email_template" -> option.Some(GetAdminEmailTemplateAction)
    "update_admin_email_template" -> option.Some(UpdateAdminEmailTemplateAction)
    "get_admin_snippets" -> option.Some(GetAdminSnippetsAction)
    "get_admin_snippet" -> option.Some(GetAdminSnippetAction)
    "delete_admin_snippet" -> option.Some(DeleteAdminSnippetAction)
    "get_admin_users" -> option.Some(GetAdminUsersAction)
    "get_admin_user" -> option.Some(GetAdminUserAction)
    "update_admin_user" -> option.Some(UpdateAdminUserAction)
    "delete_admin_account" -> option.Some(DeleteAdminAccountAction)
    "get_admin_api_logs" -> option.Some(GetAdminApiLogsAction)
    "get_admin_api_log" -> option.Some(GetAdminApiLogAction)
    "get_admin_run_logs" -> option.Some(GetAdminRunLogsAction)
    "get_admin_run_log" -> option.Some(GetAdminRunLogAction)
    "get_admin_job_logs" -> option.Some(GetAdminJobLogsAction)
    "get_admin_job_log" -> option.Some(GetAdminJobLogAction)
    "get_admin_rate_limit_policies" ->
      option.Some(GetAdminRateLimitPoliciesAction)
    "upsert_admin_rate_limit_policy" ->
      option.Some(UpsertAdminRateLimitPolicyAction)
    "get_admin_job_type_policies" -> option.Some(GetAdminJobTypePoliciesAction)
    "upsert_admin_job_type_policy" ->
      option.Some(UpsertAdminJobTypePolicyAction)
    "get_admin_docker_run_config" -> option.Some(GetAdminDockerRunConfigAction)
    "upsert_admin_docker_run_config" ->
      option.Some(UpsertAdminDockerRunConfigAction)
    "get_admin_spam_classifier_config" ->
      option.Some(GetAdminSpamClassifierConfigAction)
    "upsert_admin_spam_classifier_config" ->
      option.Some(UpsertAdminSpamClassifierConfigAction)
    "get_admin_cloudflare_config" -> option.Some(GetAdminCloudflareConfigAction)
    "upsert_admin_cloudflare_config" ->
      option.Some(UpsertAdminCloudflareConfigAction)
    "get_admin_email_config" -> option.Some(GetAdminEmailConfigAction)
    "upsert_admin_email_config" -> option.Some(UpsertAdminEmailConfigAction)
    _ -> option.None
  }
}

pub fn server_timing_policy(
  _action: AdminAction,
) -> server_timing_policy.ServerTimingPolicy {
  server_timing_policy.ExposeServerTiming
}
