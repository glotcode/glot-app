import gleam/list
import gleam/time/timestamp.{type Timestamp}
import glot_core/admin/account_dto
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
import glot_core/admin/language_version_cache_worker_config_dto as language_cache_dto
import glot_core/admin/log_worker_config_dto
import glot_core/admin/passkey_config_dto
import glot_core/admin/periodic_job_dto
import glot_core/admin/rate_limit_config_dto
import glot_core/admin/run_log_dto
import glot_core/admin/snippet_dto as admin_snippet_dto
import glot_core/admin/user_dto
import glot_core/snippet/snippet_dto
import glot_frontend/admin/effect/config
import glot_frontend/admin/effect/content
import glot_frontend/admin/effect/jobs
import glot_frontend/admin/effect/logs
import glot_frontend/admin/effect/users
import glot_frontend/admin/local_datetime.{type LocalDateTime, type ParseResult}
import glot_frontend/api/response

pub type Command(msg) {
  None
  Batch(List(Command(msg)))
  Logs(logs.Command(msg))
  Users(users.Command(msg))
  Jobs(jobs.Command(msg))
  Content(content.Command(msg))
  Config(config.Command(msg))
  OpenDialog(String)
  CloseDialog(String)
  Navigate(String)
  CurrentTime(fn(Timestamp) -> msg)
  FormatLocalDateTime(Timestamp, fn(LocalDateTime) -> msg)
  ParseLocalDateTime(String, String, fn(ParseResult) -> msg)
}

pub fn none() -> Command(msg) {
  None
}

pub fn batch(commands: List(Command(msg))) -> Command(msg) {
  Batch(commands)
}

pub fn map(command: Command(a), transform: fn(a) -> b) -> Command(b) {
  case command {
    None -> None
    Batch(commands) ->
      Batch(list.map(commands, fn(item) { map(item, transform) }))
    Logs(value) -> Logs(logs.map(value, transform))
    Users(value) -> Users(users.map(value, transform))
    Jobs(value) -> Jobs(jobs.map(value, transform))
    Content(value) -> Content(content.map(value, transform))
    Config(value) -> Config(config.map(value, transform))
    OpenDialog(id) -> OpenDialog(id)
    CloseDialog(id) -> CloseDialog(id)
    Navigate(path) -> Navigate(path)
    CurrentTime(complete) ->
      CurrentTime(fn(value) { transform(complete(value)) })
    FormatLocalDateTime(value, complete) ->
      FormatLocalDateTime(value, fn(result) { transform(complete(result)) })
    ParseLocalDateTime(date, time, complete) ->
      ParseLocalDateTime(date, time, fn(result) { transform(complete(result)) })
  }
}

pub fn get_admin_api_logs(
  request: api_log_dto.ListApiLogsRequest,
  done: fn(response.Response(api_log_dto.ListApiLogsResponse)) -> msg,
) -> Command(msg) {
  Logs(logs.GetApiLogs(request, done))
}

pub fn get_admin_api_log(
  request: api_log_dto.GetApiLogRequest,
  done: fn(response.Response(api_log_dto.GetApiLogResponse)) -> msg,
) -> Command(msg) {
  Logs(logs.GetApiLog(request, done))
}

pub fn get_admin_run_logs(
  request: run_log_dto.ListRunLogsRequest,
  done: fn(response.Response(run_log_dto.ListRunLogsResponse)) -> msg,
) -> Command(msg) {
  Logs(logs.GetRunLogs(request, done))
}

pub fn get_admin_run_log(
  request: run_log_dto.GetRunLogRequest,
  done: fn(response.Response(run_log_dto.GetRunLogResponse)) -> msg,
) -> Command(msg) {
  Logs(logs.GetRunLog(request, done))
}

pub fn get_admin_users(
  request: user_dto.ListUsersRequest,
  done: fn(response.Response(user_dto.ListUsersResponse)) -> msg,
) -> Command(msg) {
  Users(users.GetUsers(request, done))
}

pub fn get_admin_user(
  request: user_dto.GetUserRequest,
  done: fn(response.Response(user_dto.GetUserResponse)) -> msg,
) -> Command(msg) {
  Users(users.GetUser(request, done))
}

pub fn update_admin_user(
  request: user_dto.UpdateUserRequest,
  done: fn(response.Response(user_dto.UpdateUserResponse)) -> msg,
) -> Command(msg) {
  Users(users.UpdateUser(request, done))
}

pub fn delete_admin_account(
  request: account_dto.DeleteAccountRequest,
  done: fn(response.Response(Nil)) -> msg,
) -> Command(msg) {
  Users(users.DeleteAccount(request, done))
}

pub fn get_admin_periodic_jobs(
  done: fn(response.Response(periodic_job_dto.ListPeriodicJobsResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.GetPeriodicJobs(done))
}

pub fn get_admin_periodic_job(
  request: periodic_job_dto.GetPeriodicJobRequest,
  done: fn(response.Response(periodic_job_dto.GetPeriodicJobResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.GetPeriodicJob(request, done))
}

pub fn update_admin_periodic_job(
  request: periodic_job_dto.UpdatePeriodicJobRequest,
  done: fn(response.Response(periodic_job_dto.UpdatePeriodicJobResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.UpdatePeriodicJob(request, done))
}

pub fn get_admin_jobs(
  request: job_dto.ListJobsRequest,
  done: fn(response.Response(job_dto.ListJobsResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.GetJobs(request, done))
}

pub fn get_admin_job(
  request: job_dto.GetJobRequest,
  done: fn(response.Response(job_dto.GetJobResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.GetJob(request, done))
}

pub fn create_admin_job(
  request: job_dto.CreateJobRequest,
  done: fn(response.Response(job_dto.GetJobResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.CreateJob(request, done))
}

pub fn get_admin_job_logs(
  request: job_log_dto.ListJobLogsRequest,
  done: fn(response.Response(job_log_dto.ListJobLogsResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.GetJobLogs(request, done))
}

pub fn get_admin_job_log(
  request: job_log_dto.GetJobLogRequest,
  done: fn(response.Response(job_log_dto.GetJobLogResponse)) -> msg,
) -> Command(msg) {
  Jobs(jobs.GetJobLog(request, done))
}

pub fn get_admin_email_templates(
  done: fn(response.Response(email_template_dto.ListEmailTemplatesResponse)) ->
    msg,
) -> Command(msg) {
  Content(content.GetEmailTemplates(done))
}

pub fn get_admin_email_template(
  request: email_template_dto.GetEmailTemplateRequest,
  done: fn(response.Response(email_template_dto.GetEmailTemplateResponse)) ->
    msg,
) -> Command(msg) {
  Content(content.GetEmailTemplate(request, done))
}

pub fn update_admin_email_template(
  request: email_template_dto.UpdateEmailTemplateRequest,
  done: fn(response.Response(email_template_dto.UpdateEmailTemplateResponse)) ->
    msg,
) -> Command(msg) {
  Content(content.UpdateEmailTemplate(request, done))
}

pub fn get_admin_snippets(
  request: admin_snippet_dto.ListSnippetsRequest,
  done: fn(response.Response(admin_snippet_dto.ListSnippetsResponse)) -> msg,
) -> Command(msg) {
  Content(content.GetSnippets(request, done))
}

pub fn get_admin_snippet(
  request: admin_snippet_dto.GetSnippetRequest,
  done: fn(response.Response(admin_snippet_dto.GetSnippetResponse)) -> msg,
) -> Command(msg) {
  Content(content.GetSnippet(request, done))
}

pub fn delete_admin_snippet(
  request: snippet_dto.DeleteSnippetRequest,
  done: fn(response.Response(Nil)) -> msg,
) -> Command(msg) {
  Content(content.DeleteSnippet(request, done))
}

pub fn get_admin_rate_limit_policies(
  done: fn(response.Response(rate_limit_config_dto.RateLimitPoliciesResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.GetRateLimits(done))
}

pub fn get_admin_auth_config(
  done: fn(response.Response(auth_config_dto.AuthConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.GetAuth(done))
}

pub fn get_admin_passkey_config(
  done: fn(response.Response(passkey_config_dto.PasskeyConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.GetPasskey(done))
}

pub fn get_admin_job_type_policies(
  done: fn(response.Response(job_type_policy_dto.ListJobTypePoliciesResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.GetJobTypePolicies(done))
}

pub fn get_admin_debug_config(
  done: fn(response.Response(debug_config_dto.DebugConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.GetDebug(done))
}

pub fn get_admin_availability_config(
  done: fn(
    response.Response(availability_config_dto.AvailabilityConfigResponse),
  ) -> msg,
) -> Command(msg) {
  Config(config.GetAvailability(done))
}

pub fn upsert_admin_debug_config(
  request: debug_config_dto.UpsertDebugConfigRequest,
  done: fn(response.Response(debug_config_dto.DebugConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.UpsertDebug(request, done))
}

pub fn upsert_admin_availability_config(
  request: availability_config_dto.UpsertAvailabilityConfigRequest,
  done: fn(
    response.Response(availability_config_dto.AvailabilityConfigResponse),
  ) -> msg,
) -> Command(msg) {
  Config(config.UpsertAvailability(request, done))
}

pub fn upsert_admin_job_type_policy(
  request: job_type_policy_dto.UpsertJobTypePolicyRequest,
  done: fn(response.Response(job_type_policy_dto.JobTypePolicyResponse)) -> msg,
) -> Command(msg) {
  Config(config.UpsertJobTypePolicy(request, done))
}

pub fn upsert_admin_auth_config(
  request: auth_config_dto.UpsertAuthConfigRequest,
  done: fn(response.Response(auth_config_dto.AuthConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.UpsertAuth(request, done))
}

pub fn upsert_admin_passkey_config(
  request: passkey_config_dto.UpsertPasskeyConfigRequest,
  done: fn(response.Response(passkey_config_dto.PasskeyConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.UpsertPasskey(request, done))
}

pub fn get_admin_cleanup_config(
  done: fn(response.Response(cleanup_config_dto.CleanupConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.GetCleanup(done))
}

pub fn get_admin_log_worker_config(
  done: fn(response.Response(log_worker_config_dto.LogWorkerConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.GetLogWorker(done))
}

pub fn get_admin_http_pool_config(
  done: fn(response.Response(http_pool_config_dto.HttpPoolConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.GetHttpPool(done))
}

pub fn get_admin_language_version_cache_worker_config(
  done: fn(
    response.Response(
      language_cache_dto.LanguageVersionCacheWorkerConfigResponse,
    ),
  ) -> msg,
) -> Command(msg) {
  Config(config.GetLanguageCache(done))
}

pub fn upsert_admin_cleanup_config(
  request: cleanup_config_dto.UpsertCleanupConfigRequest,
  done: fn(response.Response(cleanup_config_dto.CleanupConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.UpsertCleanup(request, done))
}

pub fn upsert_admin_log_worker_config(
  request: log_worker_config_dto.UpsertLogWorkerConfigRequest,
  done: fn(response.Response(log_worker_config_dto.LogWorkerConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.UpsertLogWorker(request, done))
}

pub fn upsert_admin_http_pool_config(
  request: http_pool_config_dto.UpsertHttpPoolConfigRequest,
  done: fn(response.Response(http_pool_config_dto.HttpPoolConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.UpsertHttpPool(request, done))
}

pub fn upsert_admin_language_version_cache_worker_config(
  request: language_cache_dto.UpsertLanguageVersionCacheWorkerConfigRequest,
  done: fn(
    response.Response(
      language_cache_dto.LanguageVersionCacheWorkerConfigResponse,
    ),
  ) -> msg,
) -> Command(msg) {
  Config(config.UpsertLanguageCache(request, done))
}

pub fn upsert_admin_rate_limit_policy(
  request: rate_limit_config_dto.UpsertRateLimitPolicyRequest,
  done: fn(response.Response(rate_limit_config_dto.RateLimitPolicyResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.UpsertRateLimit(request, done))
}

pub fn get_admin_docker_run_config(
  done: fn(response.Response(docker_run_config_dto.DockerRunConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.GetDockerRun(done))
}

pub fn upsert_admin_docker_run_config(
  request: docker_run_config_dto.UpsertDockerRunConfigRequest,
  done: fn(response.Response(docker_run_config_dto.DockerRunConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.UpsertDockerRun(request, done))
}

pub fn get_admin_cloudflare_config(
  done: fn(response.Response(cloudflare_config_dto.CloudflareConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.GetCloudflare(done))
}

pub fn upsert_admin_cloudflare_config(
  request: cloudflare_config_dto.UpsertCloudflareConfigRequest,
  done: fn(response.Response(cloudflare_config_dto.CloudflareConfigResponse)) ->
    msg,
) -> Command(msg) {
  Config(config.UpsertCloudflare(request, done))
}

pub fn get_admin_email_config(
  done: fn(response.Response(email_config_dto.EmailConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.GetEmail(done))
}

pub fn upsert_admin_email_config(
  request: email_config_dto.UpsertEmailConfigRequest,
  done: fn(response.Response(email_config_dto.EmailConfigResponse)) -> msg,
) -> Command(msg) {
  Config(config.UpsertEmail(request, done))
}
