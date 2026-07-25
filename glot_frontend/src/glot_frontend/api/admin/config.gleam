import gleam/json
import glot_core/admin/auth_config_dto
import glot_core/admin/availability_config_dto
import glot_core/admin/cleanup_config_dto
import glot_core/admin/cloudflare_config_dto
import glot_core/admin/debug_config_dto
import glot_core/admin/docker_run_config_dto
import glot_core/admin/email_config_dto
import glot_core/admin/http_pool_config_dto
import glot_core/admin/job_type_policy_dto
import glot_core/admin/language_version_cache_worker_config_dto
import glot_core/admin/log_worker_config_dto
import glot_core/admin/passkey_config_dto
import glot_core/admin/rate_limit_config_dto
import glot_core/admin_action
import glot_frontend/api/request
import glot_frontend/api/response
import lustre/effect

pub fn get_admin_rate_limit_policies(
  to_msg: fn(response.Response(rate_limit_config_dto.RateLimitPoliciesResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminRateLimitPoliciesAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    rate_limit_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_auth_config(
  to_msg: fn(response.Response(auth_config_dto.AuthConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminAuthConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    auth_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_passkey_config(
  to_msg: fn(response.Response(passkey_config_dto.PasskeyConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminPasskeyConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    passkey_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_job_type_policies(
  to_msg: fn(response.Response(job_type_policy_dto.ListJobTypePoliciesResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminJobTypePoliciesAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    job_type_policy_dto.list_response_decoder(),
    to_msg,
  )
}

pub fn get_admin_debug_config(
  to_msg: fn(response.Response(debug_config_dto.DebugConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminDebugConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    debug_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_availability_config(
  to_msg: fn(
    response.Response(availability_config_dto.AvailabilityConfigResponse),
  ) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminAvailabilityConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    availability_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_debug_config(
  request: debug_config_dto.UpsertDebugConfigRequest,
  to_msg: fn(response.Response(debug_config_dto.DebugConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminDebugConfigAction, request)

  request.send_admin(
    req,
    debug_config_dto.encode_request,
    debug_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_availability_config(
  request: availability_config_dto.UpsertAvailabilityConfigRequest,
  to_msg: fn(
    response.Response(availability_config_dto.AvailabilityConfigResponse),
  ) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(
      admin_action.UpsertAdminAvailabilityConfigAction,
      request,
    )

  request.send_admin(
    req,
    availability_config_dto.encode_request,
    availability_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_job_type_policy(
  request: job_type_policy_dto.UpsertJobTypePolicyRequest,
  to_msg: fn(response.Response(job_type_policy_dto.JobTypePolicyResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminJobTypePolicyAction, request)

  request.send_admin(
    req,
    job_type_policy_dto.encode_request,
    job_type_policy_dto.policy_response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_auth_config(
  request: auth_config_dto.UpsertAuthConfigRequest,
  to_msg: fn(response.Response(auth_config_dto.AuthConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminAuthConfigAction, request)

  request.send_admin(
    req,
    auth_config_dto.encode_request,
    auth_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_passkey_config(
  request: passkey_config_dto.UpsertPasskeyConfigRequest,
  to_msg: fn(response.Response(passkey_config_dto.PasskeyConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminPasskeyConfigAction, request)

  request.send_admin(
    req,
    passkey_config_dto.encode_request,
    passkey_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_cleanup_config(
  to_msg: fn(response.Response(cleanup_config_dto.CleanupConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminCleanupConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    cleanup_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_log_worker_config(
  to_msg: fn(response.Response(log_worker_config_dto.LogWorkerConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminLogWorkerConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    log_worker_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_http_pool_config(
  to_msg: fn(response.Response(http_pool_config_dto.HttpPoolConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminHttpPoolConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    http_pool_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_language_version_cache_worker_config(
  to_msg: fn(
    response.Response(
      language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse,
    ),
  ) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(
      admin_action.GetAdminLanguageVersionCacheWorkerConfigAction,
      Nil,
    )

  request.send_admin(
    req,
    fn(_) { json.null() },
    language_version_cache_worker_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_cleanup_config(
  request: cleanup_config_dto.UpsertCleanupConfigRequest,
  to_msg: fn(response.Response(cleanup_config_dto.CleanupConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminCleanupConfigAction, request)

  request.send_admin(
    req,
    cleanup_config_dto.encode_request,
    cleanup_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_log_worker_config(
  request: log_worker_config_dto.UpsertLogWorkerConfigRequest,
  to_msg: fn(response.Response(log_worker_config_dto.LogWorkerConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminLogWorkerConfigAction, request)

  request.send_admin(
    req,
    log_worker_config_dto.encode_request,
    log_worker_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_http_pool_config(
  request: http_pool_config_dto.UpsertHttpPoolConfigRequest,
  to_msg: fn(response.Response(http_pool_config_dto.HttpPoolConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminHttpPoolConfigAction, request)

  request.send_admin(
    req,
    http_pool_config_dto.encode_request,
    http_pool_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_language_version_cache_worker_config(
  request: language_version_cache_worker_config_dto.UpsertLanguageVersionCacheWorkerConfigRequest,
  to_msg: fn(
    response.Response(
      language_version_cache_worker_config_dto.LanguageVersionCacheWorkerConfigResponse,
    ),
  ) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(
      admin_action.UpsertAdminLanguageVersionCacheWorkerConfigAction,
      request,
    )

  request.send_admin(
    req,
    language_version_cache_worker_config_dto.encode_request,
    language_version_cache_worker_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_rate_limit_policy(
  request: rate_limit_config_dto.UpsertRateLimitPolicyRequest,
  to_msg: fn(response.Response(rate_limit_config_dto.RateLimitPolicyResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminRateLimitPolicyAction, request)

  request.send_admin(
    req,
    rate_limit_config_dto.encode_request,
    rate_limit_config_dto.policy_response_decoder(),
    to_msg,
  )
}

pub fn get_admin_docker_run_config(
  to_msg: fn(response.Response(docker_run_config_dto.DockerRunConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminDockerRunConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    docker_run_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_docker_run_config(
  request: docker_run_config_dto.UpsertDockerRunConfigRequest,
  to_msg: fn(response.Response(docker_run_config_dto.DockerRunConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminDockerRunConfigAction, request)

  request.send_admin(
    req,
    docker_run_config_dto.encode_request,
    docker_run_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_cloudflare_config(
  to_msg: fn(response.Response(cloudflare_config_dto.CloudflareConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.GetAdminCloudflareConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    cloudflare_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_cloudflare_config(
  request: cloudflare_config_dto.UpsertCloudflareConfigRequest,
  to_msg: fn(response.Response(cloudflare_config_dto.CloudflareConfigResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(
      admin_action.UpsertAdminCloudflareConfigAction,
      request,
    )

  request.send_admin(
    req,
    cloudflare_config_dto.encode_request,
    cloudflare_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_admin_email_config(
  to_msg: fn(response.Response(email_config_dto.EmailConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.AdminRequest(admin_action.GetAdminEmailConfigAction, Nil)

  request.send_admin(
    req,
    fn(_) { json.null() },
    email_config_dto.response_decoder(),
    to_msg,
  )
}

pub fn upsert_admin_email_config(
  request: email_config_dto.UpsertEmailConfigRequest,
  to_msg: fn(response.Response(email_config_dto.EmailConfigResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.AdminRequest(admin_action.UpsertAdminEmailConfigAction, request)

  request.send_admin(
    req,
    email_config_dto.encode_request,
    email_config_dto.response_decoder(),
    to_msg,
  )
}
