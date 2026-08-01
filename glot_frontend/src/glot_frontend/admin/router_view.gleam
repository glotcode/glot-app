import gleam/time/timestamp.{type Timestamp}
import glot_frontend/admin/api_logs/detail_view as admin_api_log_page
import glot_frontend/admin/api_logs/list_view as admin_api_logs_page
import glot_frontend/admin/config/page_view as admin_config_page
import glot_frontend/admin/email_templates/detail_view as admin_email_template_page
import glot_frontend/admin/email_templates/list_view as admin_email_templates_page
import glot_frontend/admin/home/page as admin_page
import glot_frontend/admin/job_logs/detail_view as admin_job_log_page
import glot_frontend/admin/job_logs/list_view as admin_job_logs_page
import glot_frontend/admin/jobs/list_view as admin_jobs_page
import glot_frontend/admin/jobs/policies_view as admin_job_type_policies_page
import glot_frontend/admin/jobs/view as admin_job_page
import glot_frontend/admin/periodic_jobs/list_view as admin_periodic_jobs_page
import glot_frontend/admin/periodic_jobs/view as admin_periodic_job_page
import glot_frontend/admin/rate_limits/view as admin_rate_limits_page
import glot_frontend/admin/router_message.{
  type Msg, AdminApiLogPageMsg, AdminApiLogsPageMsg, AdminConfigPageMsg,
  AdminEmailTemplatePageMsg, AdminEmailTemplatesPageMsg, AdminJobLogPageMsg,
  AdminJobLogsPageMsg, AdminJobPageMsg, AdminJobTypePoliciesPageMsg,
  AdminJobsPageMsg, AdminPageMsg, AdminPeriodicJobPageMsg,
  AdminPeriodicJobsPageMsg, AdminRateLimitsPageMsg, AdminRunLogPageMsg,
  AdminRunLogsPageMsg, AdminSnippetPageMsg, AdminSnippetsPageMsg,
  AdminUserPageMsg, AdminUsersPageMsg,
}
import glot_frontend/admin/router_state.{
  type PageModel, AdminApiLogPage, AdminApiLogsPage, AdminConfigPage,
  AdminEmailTemplatePage, AdminEmailTemplatesPage, AdminJobLogPage,
  AdminJobLogsPage, AdminJobPage, AdminJobTypePoliciesPage, AdminJobsPage,
  AdminPage, AdminPeriodicJobPage, AdminPeriodicJobsPage, AdminRateLimitsPage,
  AdminRunLogPage, AdminRunLogsPage, AdminSnippetPage, AdminSnippetsPage,
  AdminUserPage, AdminUsersPage, EmptyPageModel,
}
import glot_frontend/admin/run_logs/detail_view as admin_run_log_page
import glot_frontend/admin/run_logs/list_view as admin_run_logs_page
import glot_frontend/admin/snippets/detail_view as admin_snippet_page
import glot_frontend/admin/snippets/list_view as admin_snippets_page
import glot_frontend/admin/users/list_view as admin_users_page
import glot_frontend/admin/users/view as admin_user_page
import glot_frontend/ui/not_found
import lustre/element.{type Element}

pub fn view(page: PageModel, now: Timestamp) -> Element(Msg) {
  case page {
    EmptyPageModel -> not_found.view()
    AdminPage(model) -> admin_page.view(model) |> element.map(AdminPageMsg)
    AdminApiLogsPage(model) ->
      admin_api_logs_page.view(model, now) |> element.map(AdminApiLogsPageMsg)
    AdminApiLogPage(model) ->
      admin_api_log_page.view(model) |> element.map(AdminApiLogPageMsg)
    AdminRunLogsPage(model) ->
      admin_run_logs_page.view(model, now) |> element.map(AdminRunLogsPageMsg)
    AdminRunLogPage(model) ->
      admin_run_log_page.view(model) |> element.map(AdminRunLogPageMsg)
    AdminPeriodicJobsPage(model) ->
      admin_periodic_jobs_page.view(model, now)
      |> element.map(AdminPeriodicJobsPageMsg)
    AdminPeriodicJobPage(model) ->
      admin_periodic_job_page.view(model, now)
      |> element.map(AdminPeriodicJobPageMsg)
    AdminUsersPage(model) ->
      admin_users_page.view(model, now) |> element.map(AdminUsersPageMsg)
    AdminUserPage(model) ->
      admin_user_page.view(model, now) |> element.map(AdminUserPageMsg)
    AdminJobsPage(model) ->
      admin_jobs_page.view(model, now) |> element.map(AdminJobsPageMsg)
    AdminJobPage(model) ->
      admin_job_page.view(model, now) |> element.map(AdminJobPageMsg)
    AdminEmailTemplatesPage(model) ->
      admin_email_templates_page.view(model)
      |> element.map(AdminEmailTemplatesPageMsg)
    AdminEmailTemplatePage(model) ->
      admin_email_template_page.view(model)
      |> element.map(AdminEmailTemplatePageMsg)
    AdminSnippetsPage(model) ->
      admin_snippets_page.view(model, now) |> element.map(AdminSnippetsPageMsg)
    AdminSnippetPage(model) ->
      admin_snippet_page.view(model) |> element.map(AdminSnippetPageMsg)
    AdminJobLogsPage(model) ->
      admin_job_logs_page.view(model, now) |> element.map(AdminJobLogsPageMsg)
    AdminJobLogPage(model) ->
      admin_job_log_page.view(model) |> element.map(AdminJobLogPageMsg)
    AdminConfigPage(model) ->
      admin_config_page.view(model) |> element.map(AdminConfigPageMsg)
    AdminRateLimitsPage(model) ->
      admin_rate_limits_page.view(model) |> element.map(AdminRateLimitsPageMsg)
    AdminJobTypePoliciesPage(model) ->
      admin_job_type_policies_page.view(model)
      |> element.map(AdminJobTypePoliciesPageMsg)
  }
}
