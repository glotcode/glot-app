import gleam/json
import glot_backend/api/model/api_result.{type ApiResult}
import glot_backend/api/presenter/error as error_presenter
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/error
import glot_backend/system/http/server_timing
import glot_backend/system/request/context
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
import glot_core/api_action.{type ApiAction}
import glot_core/api_error_dto
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/passkey_dto
import glot_core/auth/refresh_session_dto
import glot_core/auth/session_dto
import glot_core/run
import glot_core/server_timing_policy
import glot_core/snippet/snippet_dto
import wisp

pub fn from_result(
  ctx: context.Context,
  request: wisp.Request,
  action: ApiAction,
  effects: List(effect_trace.EffectMeasurement),
  total_duration_ns: Int,
  result: Result(ApiResult, error.Error),
) -> wisp.Response {
  case result {
    Ok(value) -> {
      let response = success(request, value)
      case api_action.server_timing_policy(action) {
        server_timing_policy.ExposeServerTiming ->
          wisp.set_header(
            response,
            "Server-Timing",
            server_timing.prepare(effects, total_duration_ns),
          )
        server_timing_policy.SuppressServerTiming -> response
      }
    }
    Error(error) -> error_presenter.to_response(ctx, error)
  }
}

pub fn error(
  ctx: context.Context,
  status: Int,
  code: String,
  message: String,
) -> wisp.Response {
  wisp.json_response(
    json.to_string(
      api_error_dto.encode(api_error_dto.ApiError(
        code: code,
        message: message,
        request_id: ctx.request_id,
      )),
    ),
    status,
  )
}

fn success(request: wisp.Request, result: ApiResult) -> wisp.Response {
  case result {
    api_result.AdminAnalyticsResponse(value) ->
      success_body(analytics_dto.encode_response(value))
    api_result.TrackPageviewResponse(_) -> success_body(json.null())
    api_result.RunResultResponse(value) ->
      success_body(run.encode_run_result(value))
    api_result.SessionResponse(value) ->
      success_body(json.nullable(value, session_dto.encode))
    api_result.AccountResponse(value) -> success_body(account_dto.encode(value))
    api_result.ListAccountSessionsResponse(value) ->
      success_body(account_session_dto.encode_list_account_sessions_response(
        value,
      ))
    api_result.AccountPasskeysResponse(value) ->
      success_body(passkey_dto.encode_list_account_passkeys_response(value))
    api_result.SnippetResponse(value) ->
      success_body(snippet_dto.encode_response(value))
    api_result.SnippetsResponse(value) ->
      success_body(snippet_dto.encode_list_response(value))
    api_result.DebugConfigResponse(value) ->
      success_body(debug_config_dto.encode_response(value))
    api_result.AvailabilityConfigResponse(value) ->
      success_body(availability_config_dto.encode_response(value))
    api_result.AuthConfigResponse(value) ->
      success_body(auth_config_dto.encode_response(value))
    api_result.PasskeyConfigResponse(value) ->
      success_body(passkey_config_dto.encode_response(value))
    api_result.CleanupConfigResponse(value) ->
      success_body(cleanup_config_dto.encode_response(value))
    api_result.LogWorkerConfigResponse(value) ->
      success_body(log_worker_config_dto.encode_response(value))
    api_result.HttpPoolConfigResponse(value) ->
      success_body(http_pool_config_dto.encode_response(value))
    api_result.LanguageVersionCacheWorkerConfigResponse(value) ->
      success_body(language_version_cache_worker_config_dto.encode_response(
        value,
      ))
    api_result.AdminPeriodicJobsResponse(value) ->
      success_body(periodic_job_dto.encode_list_response(value))
    api_result.AdminPeriodicJobDetailResponse(value) ->
      success_body(periodic_job_dto.encode_get_response(value))
    api_result.AdminPeriodicJobResponse(value) ->
      success_body(periodic_job_dto.encode_update_response(value))
    api_result.AdminJobsResponse(value) ->
      success_body(job_dto.encode_list_response(value))
    api_result.AdminJobResponse(value) ->
      success_body(job_dto.encode_get_response(value))
    api_result.AdminEmailTemplatesResponse(value) ->
      success_body(email_template_dto.encode_list_response(value))
    api_result.AdminEmailTemplateResponse(value) ->
      success_body(email_template_dto.encode_get_response(value))
    api_result.AdminUpdatedEmailTemplateResponse(value) ->
      success_body(email_template_dto.encode_update_response(value))
    api_result.AdminSnippetsResponse(value) ->
      success_body(admin_snippet_dto.encode_list_response(value))
    api_result.AdminSnippetResponse(value) ->
      success_body(admin_snippet_dto.encode_get_response(value))
    api_result.AdminUsersResponse(value) ->
      success_body(user_dto.encode_list_response(value))
    api_result.AdminUserDetailResponse(value) ->
      success_body(user_dto.encode_get_response(value))
    api_result.AdminUserResponse(value) ->
      success_body(user_dto.encode_update_response(value))
    api_result.AdminApiLogsResponse(value) ->
      success_body(api_log_dto.encode_list_response(value))
    api_result.AdminApiLogResponse(value) ->
      success_body(api_log_dto.encode_get_response(value))
    api_result.AdminRunLogsResponse(value) ->
      success_body(run_log_dto.encode_list_response(value))
    api_result.AdminRunLogResponse(value) ->
      success_body(run_log_dto.encode_get_response(value))
    api_result.AdminJobLogsResponse(value) ->
      success_body(job_log_dto.encode_list_response(value))
    api_result.AdminJobLogResponse(value) ->
      success_body(job_log_dto.encode_get_response(value))
    api_result.RateLimitPoliciesResponse(value) ->
      success_body(rate_limit_config_dto.encode_response(value))
    api_result.RateLimitPolicyResponse(value) ->
      success_body(rate_limit_config_dto.encode_policy_response(value))
    api_result.JobTypePoliciesResponse(value) ->
      success_body(job_type_policy_dto.encode_list_response(value))
    api_result.JobTypePolicyResponse(value) ->
      success_body(job_type_policy_dto.encode_policy_response(value))
    api_result.DockerRunConfigResponse(value) ->
      success_body(docker_run_config_dto.encode_response(value))
    api_result.CloudflareConfigResponse(value) ->
      success_body(cloudflare_config_dto.encode_response(value))
    api_result.EmailConfigResponse(value) ->
      success_body(email_config_dto.encode_response(value))
    api_result.LoginResponse(value) ->
      set_session_cookie(
        success_body(json.null()),
        request,
        value.session_token,
        value.session_cookie_max_age,
      )
    api_result.BeginPasskeyRegistrationResponse(value) ->
      success_body(passkey_dto.encode_begin_registration_response(value))
    api_result.BeginPasskeyLoginResponse(value) ->
      success_body(passkey_dto.encode_begin_login_response(value))
    api_result.FinishPasskeyLoginResponse(value) ->
      set_session_cookie(
        success_body(json.null()),
        request,
        value.session_token,
        value.session_cookie_max_age,
      )
    api_result.RefreshSessionResponse(value) ->
      set_session_cookie(
        success_body(refresh_session_dto.encode(value.response)),
        request,
        value.session_token,
        value.session_cookie_max_age,
      )
    api_result.LogoutResponse ->
      success_body(json.null())
      |> wisp.set_cookie(
        request: request,
        name: "session",
        value: "",
        security: wisp.Signed,
        max_age: 0,
      )
    api_result.NoContentResponse -> success_body(json.null())
  }
}

fn success_body(data: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(json.object([#("data", data)])), 200)
}

fn set_session_cookie(
  response: wisp.Response,
  request: wisp.Request,
  token: String,
  max_age: Int,
) -> wisp.Response {
  response
  |> wisp.set_cookie(
    request: request,
    name: "session",
    value: token,
    security: wisp.Signed,
    max_age: max_age,
  )
}
