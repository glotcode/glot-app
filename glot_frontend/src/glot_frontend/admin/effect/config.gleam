import glot_core/admin/auth_config_dto
import glot_core/admin/availability_config_dto
import glot_core/admin/cleanup_config_dto
import glot_core/admin/cloudflare_config_dto
import glot_core/admin/debug_config_dto
import glot_core/admin/docker_run_config_dto
import glot_core/admin/email_config_dto
import glot_core/admin/http_pool_config_dto
import glot_core/admin/job_type_policy_dto
import glot_core/admin/language_version_cache_worker_config_dto as language_cache_dto
import glot_core/admin/log_worker_config_dto
import glot_core/admin/passkey_config_dto
import glot_core/admin/rate_limit_config_dto
import glot_core/admin/spam_classifier_config_dto
import glot_frontend/api/response

pub type Command(msg) {
  GetRateLimits(
    fn(response.Response(rate_limit_config_dto.RateLimitPoliciesResponse)) ->
      msg,
  )
  GetAuth(fn(response.Response(auth_config_dto.AuthConfigResponse)) -> msg)
  GetPasskey(
    fn(response.Response(passkey_config_dto.PasskeyConfigResponse)) -> msg,
  )
  GetJobTypePolicies(
    fn(response.Response(job_type_policy_dto.ListJobTypePoliciesResponse)) ->
      msg,
  )
  GetDebug(fn(response.Response(debug_config_dto.DebugConfigResponse)) -> msg)
  GetAvailability(
    fn(response.Response(availability_config_dto.AvailabilityConfigResponse)) ->
      msg,
  )
  UpsertDebug(
    debug_config_dto.UpsertDebugConfigRequest,
    fn(response.Response(debug_config_dto.DebugConfigResponse)) -> msg,
  )
  UpsertAvailability(
    availability_config_dto.UpsertAvailabilityConfigRequest,
    fn(response.Response(availability_config_dto.AvailabilityConfigResponse)) ->
      msg,
  )
  UpsertJobTypePolicy(
    job_type_policy_dto.UpsertJobTypePolicyRequest,
    fn(response.Response(job_type_policy_dto.JobTypePolicyResponse)) -> msg,
  )
  UpsertAuth(
    auth_config_dto.UpsertAuthConfigRequest,
    fn(response.Response(auth_config_dto.AuthConfigResponse)) -> msg,
  )
  UpsertPasskey(
    passkey_config_dto.UpsertPasskeyConfigRequest,
    fn(response.Response(passkey_config_dto.PasskeyConfigResponse)) -> msg,
  )
  GetCleanup(
    fn(response.Response(cleanup_config_dto.CleanupConfigResponse)) -> msg,
  )
  GetLogWorker(
    fn(response.Response(log_worker_config_dto.LogWorkerConfigResponse)) -> msg,
  )
  GetHttpPool(
    fn(response.Response(http_pool_config_dto.HttpPoolConfigResponse)) -> msg,
  )
  GetLanguageCache(
    fn(
      response.Response(
        language_cache_dto.LanguageVersionCacheWorkerConfigResponse,
      ),
    ) -> msg,
  )
  UpsertCleanup(
    cleanup_config_dto.UpsertCleanupConfigRequest,
    fn(response.Response(cleanup_config_dto.CleanupConfigResponse)) -> msg,
  )
  UpsertLogWorker(
    log_worker_config_dto.UpsertLogWorkerConfigRequest,
    fn(response.Response(log_worker_config_dto.LogWorkerConfigResponse)) -> msg,
  )
  UpsertHttpPool(
    http_pool_config_dto.UpsertHttpPoolConfigRequest,
    fn(response.Response(http_pool_config_dto.HttpPoolConfigResponse)) -> msg,
  )
  UpsertLanguageCache(
    language_cache_dto.UpsertLanguageVersionCacheWorkerConfigRequest,
    fn(
      response.Response(
        language_cache_dto.LanguageVersionCacheWorkerConfigResponse,
      ),
    ) -> msg,
  )
  UpsertRateLimit(
    rate_limit_config_dto.UpsertRateLimitPolicyRequest,
    fn(response.Response(rate_limit_config_dto.RateLimitPolicyResponse)) -> msg,
  )
  GetDockerRun(
    fn(response.Response(docker_run_config_dto.DockerRunConfigResponse)) -> msg,
  )
  UpsertDockerRun(
    docker_run_config_dto.UpsertDockerRunConfigRequest,
    fn(response.Response(docker_run_config_dto.DockerRunConfigResponse)) -> msg,
  )
  GetSpamClassifier(
    fn(
      response.Response(spam_classifier_config_dto.SpamClassifierConfigResponse),
    ) -> msg,
  )
  UpsertSpamClassifier(
    spam_classifier_config_dto.UpsertSpamClassifierConfigRequest,
    fn(
      response.Response(spam_classifier_config_dto.SpamClassifierConfigResponse),
    ) -> msg,
  )
  GetCloudflare(
    fn(response.Response(cloudflare_config_dto.CloudflareConfigResponse)) -> msg,
  )
  UpsertCloudflare(
    cloudflare_config_dto.UpsertCloudflareConfigRequest,
    fn(response.Response(cloudflare_config_dto.CloudflareConfigResponse)) -> msg,
  )
  GetEmail(fn(response.Response(email_config_dto.EmailConfigResponse)) -> msg)
  UpsertEmail(
    email_config_dto.UpsertEmailConfigRequest,
    fn(response.Response(email_config_dto.EmailConfigResponse)) -> msg,
  )
}

pub fn map(command: Command(a), transform: fn(a) -> b) -> Command(b) {
  case command {
    GetRateLimits(done) -> GetRateLimits(mapped(done, transform))
    GetAuth(done) -> GetAuth(mapped(done, transform))
    GetPasskey(done) -> GetPasskey(mapped(done, transform))
    GetJobTypePolicies(done) -> GetJobTypePolicies(mapped(done, transform))
    GetDebug(done) -> GetDebug(mapped(done, transform))
    GetAvailability(done) -> GetAvailability(mapped(done, transform))
    UpsertDebug(request, done) -> UpsertDebug(request, mapped(done, transform))
    UpsertAvailability(request, done) ->
      UpsertAvailability(request, mapped(done, transform))
    UpsertJobTypePolicy(request, done) ->
      UpsertJobTypePolicy(request, mapped(done, transform))
    UpsertAuth(request, done) -> UpsertAuth(request, mapped(done, transform))
    UpsertPasskey(request, done) ->
      UpsertPasskey(request, mapped(done, transform))
    GetCleanup(done) -> GetCleanup(mapped(done, transform))
    GetLogWorker(done) -> GetLogWorker(mapped(done, transform))
    GetHttpPool(done) -> GetHttpPool(mapped(done, transform))
    GetLanguageCache(done) -> GetLanguageCache(mapped(done, transform))
    UpsertCleanup(request, done) ->
      UpsertCleanup(request, mapped(done, transform))
    UpsertLogWorker(request, done) ->
      UpsertLogWorker(request, mapped(done, transform))
    UpsertHttpPool(request, done) ->
      UpsertHttpPool(request, mapped(done, transform))
    UpsertLanguageCache(request, done) ->
      UpsertLanguageCache(request, mapped(done, transform))
    UpsertRateLimit(request, done) ->
      UpsertRateLimit(request, mapped(done, transform))
    GetDockerRun(done) -> GetDockerRun(mapped(done, transform))
    UpsertDockerRun(request, done) ->
      UpsertDockerRun(request, mapped(done, transform))
    GetSpamClassifier(done) -> GetSpamClassifier(mapped(done, transform))
    UpsertSpamClassifier(request, done) ->
      UpsertSpamClassifier(request, mapped(done, transform))
    GetCloudflare(done) -> GetCloudflare(mapped(done, transform))
    UpsertCloudflare(request, done) ->
      UpsertCloudflare(request, mapped(done, transform))
    GetEmail(done) -> GetEmail(mapped(done, transform))
    UpsertEmail(request, done) -> UpsertEmail(request, mapped(done, transform))
  }
}

fn mapped(
  complete: fn(response) -> a,
  transform: fn(a) -> b,
) -> fn(response) -> b {
  fn(result) { transform(complete(result)) }
}
