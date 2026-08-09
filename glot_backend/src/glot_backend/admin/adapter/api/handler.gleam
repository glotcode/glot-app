import gleam/dynamic
import glot_backend/admin/domain/analytics/get as get_analytics_domain
import glot_backend/admin/domain/api_log/get as get_api_log_domain
import glot_backend/admin/domain/api_log/list as get_api_logs_domain
import glot_backend/admin/domain/auth/account/delete as admin_delete_account_domain
import glot_backend/admin/domain/auth/user/get as get_user_domain
import glot_backend/admin/domain/auth/user/list as get_users_domain
import glot_backend/admin/domain/auth/user/update as update_user_domain
import glot_backend/admin/domain/config/auth/get as get_auth_config_domain
import glot_backend/admin/domain/config/auth/upsert as upsert_auth_config_domain
import glot_backend/admin/domain/config/availability/get as get_availability_config_domain
import glot_backend/admin/domain/config/availability/upsert as upsert_availability_config_domain
import glot_backend/admin/domain/config/cleanup/get as get_cleanup_config_domain
import glot_backend/admin/domain/config/cleanup/upsert as upsert_cleanup_config_domain
import glot_backend/admin/domain/config/cloudflare/get as get_cloudflare_config_domain
import glot_backend/admin/domain/config/cloudflare/upsert as upsert_cloudflare_config_domain
import glot_backend/admin/domain/config/debug/get as get_debug_config_domain
import glot_backend/admin/domain/config/debug/upsert as upsert_debug_config_domain
import glot_backend/admin/domain/config/docker_run/get as get_docker_run_config_domain
import glot_backend/admin/domain/config/docker_run/upsert as upsert_docker_run_config_domain
import glot_backend/admin/domain/config/email/get as get_email_config_domain
import glot_backend/admin/domain/config/email/upsert as upsert_email_config_domain
import glot_backend/admin/domain/config/http_pool/get as get_http_pool_config_domain
import glot_backend/admin/domain/config/http_pool/upsert as upsert_http_pool_config_domain
import glot_backend/admin/domain/config/language_version_cache_worker/get as get_language_version_cache_worker_config_domain
import glot_backend/admin/domain/config/language_version_cache_worker/upsert as upsert_language_version_cache_worker_config_domain
import glot_backend/admin/domain/config/log_worker/get as get_log_worker_config_domain
import glot_backend/admin/domain/config/log_worker/upsert as upsert_log_worker_config_domain
import glot_backend/admin/domain/config/passkey/get as get_passkey_config_domain
import glot_backend/admin/domain/config/passkey/upsert as upsert_passkey_config_domain
import glot_backend/admin/domain/config/rate_limit/list as get_rate_limit_policies_domain
import glot_backend/admin/domain/config/rate_limit/upsert as upsert_rate_limit_policy_domain
import glot_backend/admin/domain/email_template/get as get_email_template_domain
import glot_backend/admin/domain/email_template/list as get_email_templates_domain
import glot_backend/admin/domain/email_template/update as update_email_template_domain
import glot_backend/admin/domain/job/create as create_job_domain
import glot_backend/admin/domain/job/get as get_job_domain
import glot_backend/admin/domain/job/get_log as get_job_log_domain
import glot_backend/admin/domain/job/get_periodic as get_periodic_job_domain
import glot_backend/admin/domain/job/list as get_jobs_domain
import glot_backend/admin/domain/job/list_logs as get_job_logs_domain
import glot_backend/admin/domain/job/list_periodic as get_periodic_jobs_domain
import glot_backend/admin/domain/job/list_type_policies as get_job_type_policies_domain
import glot_backend/admin/domain/job/update_periodic as update_periodic_job_domain
import glot_backend/admin/domain/job/upsert_type_policy as upsert_job_type_policy_domain
import glot_backend/admin/domain/run_log/get as get_run_log_domain
import glot_backend/admin/domain/run_log/list as get_run_logs_domain
import glot_backend/admin/domain/snippet/delete as admin_delete_snippet_domain
import glot_backend/admin/domain/snippet/get as admin_get_snippet_domain
import glot_backend/admin/domain/snippet/list as get_snippets_domain
import glot_backend/api/model/api_result.{type ApiResult}
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types
import glot_backend/system/request/hydrated_context as request_context
import glot_core/admin_action.{type AdminAction}

pub fn dispatch(
  request_ctx: request_context.RequestContext,
  action: AdminAction,
  data: dynamic.Dynamic,
) -> program_types.Program(ApiResult) {
  case action {
    admin_action.GetAdminAnalyticsAction -> {
      use request <- program.and_then(get_analytics_domain.request_from_dynamic(
        data,
      ))
      get_analytics_domain.get_analytics(request_ctx, request)
      |> program.map(api_result.AdminAnalyticsResponse)
    }
    admin_action.GetAdminDebugConfigAction ->
      get_debug_config_domain.get_debug_config(request_ctx)
      |> program.map(api_result.DebugConfigResponse)
    admin_action.GetAdminAvailabilityConfigAction ->
      get_availability_config_domain.get_availability_config(request_ctx)
      |> program.map(api_result.AvailabilityConfigResponse)
    admin_action.UpsertAdminAvailabilityConfigAction -> {
      use request <- program.and_then(
        upsert_availability_config_domain.request_from_dynamic(data),
      )
      upsert_availability_config_domain.upsert_availability_config(
        request_ctx,
        request,
      )
      |> program.map(api_result.AvailabilityConfigResponse)
    }
    admin_action.UpsertAdminDebugConfigAction -> {
      use request <- program.and_then(
        upsert_debug_config_domain.request_from_dynamic(data),
      )
      upsert_debug_config_domain.upsert_debug_config(request_ctx, request)
      |> program.map(api_result.DebugConfigResponse)
    }
    admin_action.GetAdminAuthConfigAction ->
      get_auth_config_domain.get_auth_config(request_ctx)
      |> program.map(api_result.AuthConfigResponse)
    admin_action.GetAdminPasskeyConfigAction ->
      get_passkey_config_domain.get_passkey_config(request_ctx)
      |> program.map(api_result.PasskeyConfigResponse)
    admin_action.UpsertAdminAuthConfigAction -> {
      use request <- program.and_then(
        upsert_auth_config_domain.request_from_dynamic(data),
      )
      upsert_auth_config_domain.upsert_auth_config(request_ctx, request)
      |> program.map(api_result.AuthConfigResponse)
    }
    admin_action.UpsertAdminPasskeyConfigAction -> {
      use request <- program.and_then(
        upsert_passkey_config_domain.request_from_dynamic(data),
      )
      upsert_passkey_config_domain.upsert_passkey_config(request_ctx, request)
      |> program.map(api_result.PasskeyConfigResponse)
    }
    admin_action.GetAdminCleanupConfigAction ->
      get_cleanup_config_domain.get_cleanup_config(request_ctx)
      |> program.map(api_result.CleanupConfigResponse)
    admin_action.UpsertAdminCleanupConfigAction -> {
      use request <- program.and_then(
        upsert_cleanup_config_domain.request_from_dynamic(data),
      )
      upsert_cleanup_config_domain.upsert_cleanup_config(request_ctx, request)
      |> program.map(api_result.CleanupConfigResponse)
    }
    admin_action.GetAdminLogWorkerConfigAction ->
      get_log_worker_config_domain.get_log_worker_config(request_ctx)
      |> program.map(api_result.LogWorkerConfigResponse)
    admin_action.UpsertAdminLogWorkerConfigAction -> {
      use request <- program.and_then(
        upsert_log_worker_config_domain.request_from_dynamic(data),
      )
      upsert_log_worker_config_domain.upsert_log_worker_config(
        request_ctx,
        request,
      )
      |> program.map(api_result.LogWorkerConfigResponse)
    }
    admin_action.GetAdminHttpPoolConfigAction ->
      get_http_pool_config_domain.get_http_pool_config(request_ctx)
      |> program.map(api_result.HttpPoolConfigResponse)
    admin_action.UpsertAdminHttpPoolConfigAction -> {
      use request <- program.and_then(
        upsert_http_pool_config_domain.request_from_dynamic(data),
      )
      upsert_http_pool_config_domain.upsert_http_pool_config(
        request_ctx,
        request,
      )
      |> program.map(api_result.HttpPoolConfigResponse)
    }
    admin_action.GetAdminLanguageVersionCacheWorkerConfigAction ->
      get_language_version_cache_worker_config_domain.get_language_version_cache_worker_config(
        request_ctx,
      )
      |> program.map(api_result.LanguageVersionCacheWorkerConfigResponse)
    admin_action.UpsertAdminLanguageVersionCacheWorkerConfigAction -> {
      use request <- program.and_then(
        upsert_language_version_cache_worker_config_domain.request_from_dynamic(
          data,
        ),
      )
      upsert_language_version_cache_worker_config_domain.upsert_language_version_cache_worker_config(
        request_ctx,
        request,
      )
      |> program.map(api_result.LanguageVersionCacheWorkerConfigResponse)
    }
    admin_action.GetAdminPeriodicJobsAction ->
      get_periodic_jobs_domain.get_periodic_jobs(request_ctx)
      |> program.map(api_result.AdminPeriodicJobsResponse)
    admin_action.GetAdminPeriodicJobAction -> {
      use request <- program.and_then(
        get_periodic_job_domain.request_from_dynamic(data),
      )
      get_periodic_job_domain.get_periodic_job(request_ctx, request)
      |> program.map(api_result.AdminPeriodicJobDetailResponse)
    }
    admin_action.UpdateAdminPeriodicJobAction -> {
      use request <- program.and_then(
        update_periodic_job_domain.request_from_dynamic(data),
      )
      update_periodic_job_domain.update_periodic_job(request_ctx, request)
      |> program.map(api_result.AdminPeriodicJobResponse)
    }
    admin_action.GetAdminJobsAction -> {
      use request <- program.and_then(get_jobs_domain.request_from_dynamic(data))
      get_jobs_domain.get_jobs(request_ctx, request)
      |> program.map(api_result.AdminJobsResponse)
    }
    admin_action.GetAdminJobAction -> {
      use request <- program.and_then(get_job_domain.request_from_dynamic(data))
      get_job_domain.get_job(request_ctx, request)
      |> program.map(api_result.AdminJobResponse)
    }
    admin_action.CreateAdminJobAction -> {
      use request <- program.and_then(create_job_domain.request_from_dynamic(
        data,
      ))
      create_job_domain.create_job(request_ctx, request)
      |> program.map(api_result.AdminJobResponse)
    }
    admin_action.GetAdminEmailTemplatesAction ->
      get_email_templates_domain.get_email_templates(request_ctx)
      |> program.map(api_result.AdminEmailTemplatesResponse)
    admin_action.GetAdminEmailTemplateAction -> {
      use request <- program.and_then(
        get_email_template_domain.request_from_dynamic(data),
      )
      get_email_template_domain.get_email_template(request_ctx, request)
      |> program.map(api_result.AdminEmailTemplateResponse)
    }
    admin_action.UpdateAdminEmailTemplateAction -> {
      use request <- program.and_then(
        update_email_template_domain.request_from_dynamic(data),
      )
      update_email_template_domain.update_email_template(request_ctx, request)
      |> program.map(api_result.AdminUpdatedEmailTemplateResponse)
    }
    admin_action.GetAdminSnippetsAction -> {
      use request <- program.and_then(get_snippets_domain.request_from_dynamic(
        data,
      ))
      get_snippets_domain.get_snippets(request_ctx, request)
      |> program.map(api_result.AdminSnippetsResponse)
    }
    admin_action.GetAdminSnippetAction -> {
      use request <- program.and_then(
        admin_get_snippet_domain.request_from_dynamic(data),
      )
      admin_get_snippet_domain.get_snippet(request_ctx, request)
      |> program.map(api_result.AdminSnippetResponse)
    }
    admin_action.DeleteAdminSnippetAction -> {
      use request <- program.and_then(
        admin_delete_snippet_domain.request_from_dynamic(data),
      )
      admin_delete_snippet_domain.delete_snippet(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    admin_action.GetAdminUsersAction -> {
      use request <- program.and_then(get_users_domain.request_from_dynamic(
        data,
      ))
      get_users_domain.get_users(request_ctx, request)
      |> program.map(api_result.AdminUsersResponse)
    }
    admin_action.GetAdminUserAction -> {
      use request <- program.and_then(get_user_domain.request_from_dynamic(data))
      get_user_domain.get_user(request_ctx, request)
      |> program.map(api_result.AdminUserDetailResponse)
    }
    admin_action.UpdateAdminUserAction -> {
      use request <- program.and_then(update_user_domain.request_from_dynamic(
        data,
      ))
      update_user_domain.update_user(request_ctx, request)
      |> program.map(api_result.AdminUserResponse)
    }
    admin_action.DeleteAdminAccountAction -> {
      use request <- program.and_then(
        admin_delete_account_domain.request_from_dynamic(data),
      )
      admin_delete_account_domain.delete_account(request_ctx, request)
      |> program.map(fn(_) { api_result.NoContentResponse })
    }
    admin_action.GetAdminApiLogsAction -> {
      use request <- program.and_then(get_api_logs_domain.request_from_dynamic(
        data,
      ))
      get_api_logs_domain.get_api_logs(request_ctx, request)
      |> program.map(api_result.AdminApiLogsResponse)
    }
    admin_action.GetAdminApiLogAction -> {
      use request <- program.and_then(get_api_log_domain.request_from_dynamic(
        data,
      ))
      get_api_log_domain.get_api_log(request_ctx, request)
      |> program.map(api_result.AdminApiLogResponse)
    }
    admin_action.GetAdminRunLogsAction -> {
      use request <- program.and_then(get_run_logs_domain.request_from_dynamic(
        data,
      ))
      get_run_logs_domain.get_run_logs(request_ctx, request)
      |> program.map(api_result.AdminRunLogsResponse)
    }
    admin_action.GetAdminRunLogAction -> {
      use request <- program.and_then(get_run_log_domain.request_from_dynamic(
        data,
      ))
      get_run_log_domain.get_run_log(request_ctx, request)
      |> program.map(api_result.AdminRunLogResponse)
    }
    admin_action.GetAdminJobLogsAction -> {
      use request <- program.and_then(get_job_logs_domain.request_from_dynamic(
        data,
      ))
      get_job_logs_domain.get_job_logs(request_ctx, request)
      |> program.map(api_result.AdminJobLogsResponse)
    }
    admin_action.GetAdminJobLogAction -> {
      use request <- program.and_then(get_job_log_domain.request_from_dynamic(
        data,
      ))
      get_job_log_domain.get_job_log(request_ctx, request)
      |> program.map(api_result.AdminJobLogResponse)
    }
    admin_action.GetAdminRateLimitPoliciesAction ->
      get_rate_limit_policies_domain.get_rate_limit_policies(request_ctx)
      |> program.map(api_result.RateLimitPoliciesResponse)
    admin_action.UpsertAdminRateLimitPolicyAction -> {
      use request <- program.and_then(
        upsert_rate_limit_policy_domain.request_from_dynamic(data),
      )
      upsert_rate_limit_policy_domain.upsert_rate_limit_policy(
        request_ctx,
        request,
      )
      |> program.map(api_result.RateLimitPolicyResponse)
    }
    admin_action.GetAdminJobTypePoliciesAction ->
      get_job_type_policies_domain.get_job_type_policies(request_ctx)
      |> program.map(api_result.JobTypePoliciesResponse)
    admin_action.UpsertAdminJobTypePolicyAction -> {
      use request <- program.and_then(
        upsert_job_type_policy_domain.request_from_dynamic(data),
      )
      upsert_job_type_policy_domain.upsert_job_type_policy(request_ctx, request)
      |> program.map(api_result.JobTypePolicyResponse)
    }
    admin_action.GetAdminDockerRunConfigAction ->
      get_docker_run_config_domain.get_docker_run_config(request_ctx)
      |> program.map(api_result.DockerRunConfigResponse)
    admin_action.UpsertAdminDockerRunConfigAction -> {
      use request <- program.and_then(
        upsert_docker_run_config_domain.request_from_dynamic(data),
      )
      upsert_docker_run_config_domain.upsert_docker_run_config(
        request_ctx,
        request,
      )
      |> program.map(api_result.DockerRunConfigResponse)
    }
    admin_action.GetAdminCloudflareConfigAction ->
      get_cloudflare_config_domain.get_cloudflare_config(request_ctx)
      |> program.map(api_result.CloudflareConfigResponse)
    admin_action.UpsertAdminCloudflareConfigAction -> {
      use request <- program.and_then(
        upsert_cloudflare_config_domain.request_from_dynamic(data),
      )
      upsert_cloudflare_config_domain.upsert_cloudflare_config(
        request_ctx,
        request,
      )
      |> program.map(api_result.CloudflareConfigResponse)
    }
    admin_action.GetAdminEmailConfigAction ->
      get_email_config_domain.get_email_config(request_ctx)
      |> program.map(api_result.EmailConfigResponse)
    admin_action.UpsertAdminEmailConfigAction -> {
      use request <- program.and_then(
        upsert_email_config_domain.request_from_dynamic(data),
      )
      upsert_email_config_domain.upsert_email_config(request_ctx, request)
      |> program.map(api_result.EmailConfigResponse)
    }
  }
}
