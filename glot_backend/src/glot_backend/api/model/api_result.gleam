import gleam/option
import glot_backend/auth/domain/login_token/login as login_domain
import glot_backend/auth/domain/session/issue as session_issue_domain
import glot_backend/auth/domain/session/refresh as refresh_session_domain
import glot_backend/logging/pageview/domain/track as track_pageview_domain
import glot_core/admin/analytics_dto
import glot_core/admin/api_log_dto
import glot_core/admin/auth_config_dto
import glot_core/admin/availability_config_dto
import glot_core/admin/cleanup_config_dto
import glot_core/admin/cloudflare_config_dto
import glot_core/admin/debug_config_dto
import glot_core/admin/docker_run_config_dto
import glot_core/admin/email_config_dto
import glot_core/admin/email_template_dto
import glot_core/admin/http_pool_config_dto
import glot_core/admin/job_dto
import glot_core/admin/job_log_dto
import glot_core/admin/job_type_policy_dto
import glot_core/admin/language_version_cache_worker_config_dto
import glot_core/admin/log_worker_config_dto
import glot_core/admin/passkey_config_dto
import glot_core/admin/periodic_job_dto
import glot_core/admin/rate_limit_config_dto
import glot_core/admin/run_log_dto
import glot_core/admin/snippet_dto as admin_snippet_dto
import glot_core/admin/user_dto
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/passkey_dto
import glot_core/auth/session_dto
import glot_core/run
import glot_core/snippet/snippet_dto

pub type ApiResult {
  AdminAnalyticsResponse(analytics_dto.AnalyticsResponse)
  TrackPageviewResponse(track_pageview_domain.TrackedPageview)
  RunResultResponse(run.RunResult)
  SessionResponse(option.Option(session_dto.SessionResponse))
  AccountResponse(account_dto.AccountResponse)
  ListAccountSessionsResponse(account_session_dto.ListAccountSessionsResponse)
  AccountPasskeysResponse(passkey_dto.ListAccountPasskeysResponse)
  SnippetResponse(snippet_dto.SnippetResponse)
  SnippetsResponse(snippet_dto.ListSnippetsResponse)
  DebugConfigResponse(debug_config_dto.DebugConfigResponse)
  AvailabilityConfigResponse(availability_config_dto.AvailabilityConfigResponse)
  AuthConfigResponse(auth_config_dto.AuthConfigResponse)
  PasskeyConfigResponse(passkey_config_dto.PasskeyConfigResponse)
  CleanupConfigResponse(cleanup_config_dto.CleanupConfigResponse)
  LogWorkerConfigResponse(log_worker_config_dto.LogWorkerConfigResponse)
  HttpPoolConfigResponse(http_pool_config_dto.HttpPoolConfigResponse)
  LanguageVersionCacheWorkerConfigResponse(
    language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse,
  )
  AdminPeriodicJobsResponse(periodic_job_dto.ListPeriodicJobsResponse)
  AdminPeriodicJobDetailResponse(periodic_job_dto.GetPeriodicJobResponse)
  AdminPeriodicJobResponse(periodic_job_dto.UpdatePeriodicJobResponse)
  AdminJobsResponse(job_dto.ListJobsResponse)
  AdminJobResponse(job_dto.GetJobResponse)
  AdminEmailTemplatesResponse(email_template_dto.ListEmailTemplatesResponse)
  AdminEmailTemplateResponse(email_template_dto.GetEmailTemplateResponse)
  AdminUpdatedEmailTemplateResponse(
    email_template_dto.UpdateEmailTemplateResponse,
  )
  AdminSnippetsResponse(admin_snippet_dto.ListSnippetsResponse)
  AdminSnippetResponse(admin_snippet_dto.GetSnippetResponse)
  AdminUsersResponse(user_dto.ListUsersResponse)
  AdminUserDetailResponse(user_dto.GetUserResponse)
  AdminUserResponse(user_dto.UpdateUserResponse)
  AdminApiLogsResponse(api_log_dto.ListApiLogsResponse)
  AdminApiLogResponse(api_log_dto.GetApiLogResponse)
  AdminRunLogsResponse(run_log_dto.ListRunLogsResponse)
  AdminRunLogResponse(run_log_dto.GetRunLogResponse)
  AdminJobLogsResponse(job_log_dto.ListJobLogsResponse)
  AdminJobLogResponse(job_log_dto.GetJobLogResponse)
  RateLimitPoliciesResponse(rate_limit_config_dto.RateLimitPoliciesResponse)
  RateLimitPolicyResponse(rate_limit_config_dto.RateLimitPolicyResponse)
  JobTypePoliciesResponse(job_type_policy_dto.ListJobTypePoliciesResponse)
  JobTypePolicyResponse(job_type_policy_dto.JobTypePolicyResponse)
  DockerRunConfigResponse(docker_run_config_dto.DockerRunConfigResponse)
  CloudflareConfigResponse(cloudflare_config_dto.CloudflareConfigResponse)
  EmailConfigResponse(email_config_dto.EmailConfigResponse)
  LoginResponse(login_domain.LoginResult)
  BeginPasskeyRegistrationResponse(passkey_dto.BeginPasskeyRegistrationResponse)
  BeginPasskeyLoginResponse(passkey_dto.BeginPasskeyLoginResponse)
  FinishPasskeyLoginResponse(session_issue_domain.SessionIssueResult)
  RefreshSessionResponse(refresh_session_domain.RefreshSessionResult)
  LogoutResponse
  NoContentResponse
}
