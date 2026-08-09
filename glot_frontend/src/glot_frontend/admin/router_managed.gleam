import glot_core/route
import glot_frontend/admin/analytics/managed as admin_analytics_page
import glot_frontend/admin/api_logs/detail_managed as admin_api_log_page
import glot_frontend/admin/api_logs/list_managed as admin_api_logs_page
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/page_managed as admin_config_page
import glot_frontend/admin/email_templates/detail_managed as admin_email_template_page
import glot_frontend/admin/email_templates/list_managed as admin_email_templates_page
import glot_frontend/admin/home/page as admin_page
import glot_frontend/admin/job_logs/detail_managed as admin_job_log_page
import glot_frontend/admin/job_logs/list_managed as admin_job_logs_page
import glot_frontend/admin/jobs/list_managed as admin_jobs_page
import glot_frontend/admin/jobs/managed as admin_job_page
import glot_frontend/admin/jobs/policies_managed as admin_job_type_policies_page
import glot_frontend/admin/periodic_jobs/list_managed as admin_periodic_jobs_page
import glot_frontend/admin/periodic_jobs/managed as admin_periodic_job_page
import glot_frontend/admin/rate_limits/managed as admin_rate_limits_page
import glot_frontend/admin/router_message.{
  AdminAnalyticsPageMsg, AdminApiLogPageMsg, AdminApiLogsPageMsg,
  AdminConfigPageMsg, AdminEmailTemplatePageMsg, AdminEmailTemplatesPageMsg,
  AdminJobLogPageMsg, AdminJobLogsPageMsg, AdminJobPageMsg,
  AdminJobTypePoliciesPageMsg, AdminJobsPageMsg, AdminPageMsg,
  AdminPeriodicJobPageMsg, AdminPeriodicJobsPageMsg, AdminRateLimitsPageMsg,
  AdminRunLogPageMsg, AdminRunLogsPageMsg, AdminSnippetPageMsg,
  AdminSnippetsPageMsg, AdminUserPageMsg, AdminUsersPageMsg,
}
import glot_frontend/admin/router_state.{
  type PageModel, AdminAnalyticsPage, AdminApiLogPage, AdminApiLogsPage,
  AdminConfigPage, AdminEmailTemplatePage, AdminEmailTemplatesPage,
  AdminJobLogPage, AdminJobLogsPage, AdminJobPage, AdminJobTypePoliciesPage,
  AdminJobsPage, AdminPage, AdminPeriodicJobPage, AdminPeriodicJobsPage,
  AdminRateLimitsPage, AdminRunLogPage, AdminRunLogsPage, AdminSnippetPage,
  AdminSnippetsPage, AdminUserPage, AdminUsersPage, EmptyPageModel,
}
import glot_frontend/admin/run_logs/detail_managed as admin_run_log_page
import glot_frontend/admin/run_logs/list_managed as admin_run_logs_page
import glot_frontend/admin/snippets/detail_managed as admin_snippet_page
import glot_frontend/admin/snippets/list_managed as admin_snippets_page
import glot_frontend/admin/users/list_managed as admin_users_page
import glot_frontend/admin/users/managed as admin_user_page

pub type Model =
  router_state.Model

pub type Msg =
  router_message.Msg

pub fn empty() -> Model {
  router_state.new(EmptyPageModel)
}

pub fn init(
  admin_route: route.AdminRoute,
  is_admin: Bool,
) -> #(Model, admin_effect.Command(Msg)) {
  let #(page_model, page_command) = init_page(admin_route)
  let model = router_state.new(page_model)
  case is_admin {
    False -> #(model, page_command)
    True -> {
      let #(loaded_model, load_command) = session_loaded(model)
      #(loaded_model, admin_effect.batch([page_command, load_command]))
    }
  }
}

fn init_page(
  admin_route: route.AdminRoute,
) -> #(PageModel, admin_effect.Command(Msg)) {
  case admin_route {
    route.AdminHome -> lift_page(admin_page.init(), AdminPage, AdminPageMsg)
    route.AdminAnalytics ->
      lift_page(
        admin_analytics_page.init(),
        AdminAnalyticsPage,
        AdminAnalyticsPageMsg,
      )
    route.AdminApiLogs(query) ->
      lift_page(
        admin_api_logs_page.init(query),
        AdminApiLogsPage,
        AdminApiLogsPageMsg,
      )
    route.AdminApiLog(id) ->
      lift_page(
        admin_api_log_page.init(id),
        AdminApiLogPage,
        AdminApiLogPageMsg,
      )
    route.AdminRunLogs(query) ->
      lift_page(
        admin_run_logs_page.init(query),
        AdminRunLogsPage,
        AdminRunLogsPageMsg,
      )
    route.AdminRunLog(id) ->
      lift_page(
        admin_run_log_page.init(id),
        AdminRunLogPage,
        AdminRunLogPageMsg,
      )
    route.AdminPeriodicJobs ->
      lift_page(
        admin_periodic_jobs_page.init(),
        AdminPeriodicJobsPage,
        AdminPeriodicJobsPageMsg,
      )
    route.AdminPeriodicJob(id) ->
      lift_page(
        admin_periodic_job_page.init(id),
        AdminPeriodicJobPage,
        AdminPeriodicJobPageMsg,
      )
    route.AdminUsers(query) ->
      lift_page(admin_users_page.init(query), AdminUsersPage, AdminUsersPageMsg)
    route.AdminUser(id) ->
      lift_page(admin_user_page.init(id), AdminUserPage, AdminUserPageMsg)
    route.AdminJobs(query) ->
      lift_page(admin_jobs_page.init(query), AdminJobsPage, AdminJobsPageMsg)
    route.AdminJob(job_id) ->
      lift_page(admin_job_page.init(job_id), AdminJobPage, AdminJobPageMsg)
    route.AdminEmailTemplates ->
      lift_page(
        admin_email_templates_page.init(),
        AdminEmailTemplatesPage,
        AdminEmailTemplatesPageMsg,
      )
    route.AdminEmailTemplate(name) ->
      lift_page(
        admin_email_template_page.init(name),
        AdminEmailTemplatePage,
        AdminEmailTemplatePageMsg,
      )
    route.AdminSnippets(query) ->
      lift_page(
        admin_snippets_page.init(query),
        AdminSnippetsPage,
        AdminSnippetsPageMsg,
      )
    route.AdminSnippet(slug) ->
      lift_page(
        admin_snippet_page.init(slug),
        AdminSnippetPage,
        AdminSnippetPageMsg,
      )
    route.AdminJobLogs(query) ->
      lift_page(
        admin_job_logs_page.init(query),
        AdminJobLogsPage,
        AdminJobLogsPageMsg,
      )
    route.AdminJobLog(id) ->
      lift_page(
        admin_job_log_page.init(id),
        AdminJobLogPage,
        AdminJobLogPageMsg,
      )
    route.AdminConfig ->
      lift_page(admin_config_page.init(), AdminConfigPage, AdminConfigPageMsg)
    route.AdminRateLimits ->
      lift_page(
        admin_rate_limits_page.init(),
        AdminRateLimitsPage,
        AdminRateLimitsPageMsg,
      )
    route.AdminJobTypePolicies ->
      lift_page(
        admin_job_type_policies_page.init(),
        AdminJobTypePoliciesPage,
        AdminJobTypePoliciesPageMsg,
      )
  }
}

pub fn session_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case router_state.page(model) {
    AdminAnalyticsPage(page_model) ->
      lift_router_page(
        admin_analytics_page.ensure_loaded(page_model),
        AdminAnalyticsPage,
        AdminAnalyticsPageMsg,
      )
    AdminApiLogsPage(page_model) ->
      lift_router_page(
        admin_api_logs_page.ensure_loaded(page_model),
        AdminApiLogsPage,
        AdminApiLogsPageMsg,
      )
    AdminApiLogPage(page_model) ->
      lift_router_page(
        admin_api_log_page.ensure_loaded(page_model),
        AdminApiLogPage,
        AdminApiLogPageMsg,
      )
    AdminRunLogsPage(page_model) ->
      lift_router_page(
        admin_run_logs_page.ensure_loaded(page_model),
        AdminRunLogsPage,
        AdminRunLogsPageMsg,
      )
    AdminRunLogPage(page_model) ->
      lift_router_page(
        admin_run_log_page.ensure_loaded(page_model),
        AdminRunLogPage,
        AdminRunLogPageMsg,
      )
    AdminPeriodicJobsPage(page_model) ->
      lift_router_page(
        admin_periodic_jobs_page.ensure_loaded(page_model),
        AdminPeriodicJobsPage,
        AdminPeriodicJobsPageMsg,
      )
    AdminPeriodicJobPage(page_model) ->
      lift_router_page(
        admin_periodic_job_page.ensure_loaded(page_model),
        AdminPeriodicJobPage,
        AdminPeriodicJobPageMsg,
      )
    AdminUsersPage(page_model) ->
      lift_router_page(
        admin_users_page.ensure_loaded(page_model),
        AdminUsersPage,
        AdminUsersPageMsg,
      )
    AdminUserPage(page_model) ->
      lift_router_page(
        admin_user_page.ensure_loaded(page_model),
        AdminUserPage,
        AdminUserPageMsg,
      )
    AdminJobsPage(page_model) ->
      lift_router_page(
        admin_jobs_page.ensure_loaded(page_model),
        AdminJobsPage,
        AdminJobsPageMsg,
      )
    AdminJobPage(page_model) ->
      lift_router_page(
        admin_job_page.ensure_loaded(page_model),
        AdminJobPage,
        AdminJobPageMsg,
      )
    AdminEmailTemplatesPage(page_model) ->
      lift_router_page(
        admin_email_templates_page.ensure_loaded(page_model),
        AdminEmailTemplatesPage,
        AdminEmailTemplatesPageMsg,
      )
    AdminEmailTemplatePage(page_model) ->
      lift_router_page(
        admin_email_template_page.ensure_loaded(page_model),
        AdminEmailTemplatePage,
        AdminEmailTemplatePageMsg,
      )
    AdminSnippetsPage(page_model) ->
      lift_router_page(
        admin_snippets_page.ensure_loaded(page_model),
        AdminSnippetsPage,
        AdminSnippetsPageMsg,
      )
    AdminSnippetPage(page_model) ->
      lift_router_page(
        admin_snippet_page.ensure_loaded(page_model),
        AdminSnippetPage,
        AdminSnippetPageMsg,
      )
    AdminJobLogsPage(page_model) ->
      lift_router_page(
        admin_job_logs_page.ensure_loaded(page_model),
        AdminJobLogsPage,
        AdminJobLogsPageMsg,
      )
    AdminJobLogPage(page_model) ->
      lift_router_page(
        admin_job_log_page.ensure_loaded(page_model),
        AdminJobLogPage,
        AdminJobLogPageMsg,
      )
    AdminConfigPage(page_model) ->
      lift_router_page(
        admin_config_page.ensure_loaded(page_model),
        AdminConfigPage,
        AdminConfigPageMsg,
      )
    AdminRateLimitsPage(page_model) ->
      lift_router_page(
        admin_rate_limits_page.ensure_loaded(page_model),
        AdminRateLimitsPage,
        AdminRateLimitsPageMsg,
      )
    AdminJobTypePoliciesPage(page_model) ->
      lift_router_page(
        admin_job_type_policies_page.ensure_loaded(page_model),
        AdminJobTypePoliciesPage,
        AdminJobTypePoliciesPageMsg,
      )

    AdminPage(_) | EmptyPageModel -> #(model, admin_effect.none())
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg, router_state.page(model) {
    AdminAnalyticsPageMsg(page_msg), AdminAnalyticsPage(page_model) ->
      lift_router_page(
        admin_analytics_page.update(page_model, page_msg),
        AdminAnalyticsPage,
        AdminAnalyticsPageMsg,
      )
    AdminPageMsg(page_msg), AdminPage(page_model) ->
      lift_router_page(
        admin_page.update(page_model, page_msg),
        AdminPage,
        AdminPageMsg,
      )
    AdminApiLogsPageMsg(page_msg), AdminApiLogsPage(page_model) ->
      lift_router_page(
        admin_api_logs_page.update(page_model, page_msg),
        AdminApiLogsPage,
        AdminApiLogsPageMsg,
      )
    AdminApiLogPageMsg(page_msg), AdminApiLogPage(page_model) ->
      lift_router_page(
        admin_api_log_page.update(page_model, page_msg),
        AdminApiLogPage,
        AdminApiLogPageMsg,
      )
    AdminRunLogsPageMsg(page_msg), AdminRunLogsPage(page_model) ->
      lift_router_page(
        admin_run_logs_page.update(page_model, page_msg),
        AdminRunLogsPage,
        AdminRunLogsPageMsg,
      )
    AdminRunLogPageMsg(page_msg), AdminRunLogPage(page_model) ->
      lift_router_page(
        admin_run_log_page.update(page_model, page_msg),
        AdminRunLogPage,
        AdminRunLogPageMsg,
      )
    AdminPeriodicJobsPageMsg(page_msg), AdminPeriodicJobsPage(page_model) ->
      lift_router_page(
        admin_periodic_jobs_page.update(page_model, page_msg),
        AdminPeriodicJobsPage,
        AdminPeriodicJobsPageMsg,
      )
    AdminPeriodicJobPageMsg(page_msg), AdminPeriodicJobPage(page_model) ->
      lift_router_page(
        admin_periodic_job_page.update(page_model, page_msg),
        AdminPeriodicJobPage,
        AdminPeriodicJobPageMsg,
      )
    AdminUsersPageMsg(page_msg), AdminUsersPage(page_model) ->
      lift_router_page(
        admin_users_page.update(page_model, page_msg),
        AdminUsersPage,
        AdminUsersPageMsg,
      )
    AdminUserPageMsg(page_msg), AdminUserPage(page_model) ->
      lift_router_page(
        admin_user_page.update(page_model, page_msg),
        AdminUserPage,
        AdminUserPageMsg,
      )
    AdminJobsPageMsg(page_msg), AdminJobsPage(page_model) ->
      lift_router_page(
        admin_jobs_page.update(page_model, page_msg),
        AdminJobsPage,
        AdminJobsPageMsg,
      )
    AdminJobPageMsg(page_msg), AdminJobPage(page_model) ->
      lift_router_page(
        admin_job_page.update(page_model, page_msg),
        AdminJobPage,
        AdminJobPageMsg,
      )
    AdminEmailTemplatesPageMsg(page_msg), AdminEmailTemplatesPage(page_model) ->
      lift_router_page(
        admin_email_templates_page.update(page_model, page_msg),
        AdminEmailTemplatesPage,
        AdminEmailTemplatesPageMsg,
      )
    AdminEmailTemplatePageMsg(page_msg), AdminEmailTemplatePage(page_model) ->
      lift_router_page(
        admin_email_template_page.update(page_model, page_msg),
        AdminEmailTemplatePage,
        AdminEmailTemplatePageMsg,
      )
    AdminSnippetsPageMsg(page_msg), AdminSnippetsPage(page_model) ->
      lift_router_page(
        admin_snippets_page.update(page_model, page_msg),
        AdminSnippetsPage,
        AdminSnippetsPageMsg,
      )
    AdminSnippetPageMsg(page_msg), AdminSnippetPage(page_model) ->
      lift_router_page(
        admin_snippet_page.update(page_model, page_msg),
        AdminSnippetPage,
        AdminSnippetPageMsg,
      )
    AdminJobLogsPageMsg(page_msg), AdminJobLogsPage(page_model) ->
      lift_router_page(
        admin_job_logs_page.update(page_model, page_msg),
        AdminJobLogsPage,
        AdminJobLogsPageMsg,
      )
    AdminJobLogPageMsg(page_msg), AdminJobLogPage(page_model) ->
      lift_router_page(
        admin_job_log_page.update(page_model, page_msg),
        AdminJobLogPage,
        AdminJobLogPageMsg,
      )
    AdminConfigPageMsg(page_msg), AdminConfigPage(page_model) ->
      lift_router_page(
        admin_config_page.update(page_model, page_msg),
        AdminConfigPage,
        AdminConfigPageMsg,
      )
    AdminRateLimitsPageMsg(page_msg), AdminRateLimitsPage(page_model) ->
      lift_router_page(
        admin_rate_limits_page.update(page_model, page_msg),
        AdminRateLimitsPage,
        AdminRateLimitsPageMsg,
      )
    AdminJobTypePoliciesPageMsg(page_msg), AdminJobTypePoliciesPage(page_model)
    ->
      lift_router_page(
        admin_job_type_policies_page.update(page_model, page_msg),
        AdminJobTypePoliciesPage,
        AdminJobTypePoliciesPageMsg,
      )
    _, _ -> #(model, admin_effect.none())
  }
}

fn lift_page(
  transition: #(child_model, admin_effect.Command(child_msg)),
  wrap_model: fn(child_model) -> PageModel,
  wrap_msg: fn(child_msg) -> Msg,
) -> #(PageModel, admin_effect.Command(Msg)) {
  let #(model, command) = transition
  #(wrap_model(model), admin_effect.map(command, wrap_msg))
}

fn lift_router_page(
  transition: #(child_model, admin_effect.Command(child_msg)),
  wrap_model: fn(child_model) -> PageModel,
  wrap_msg: fn(child_msg) -> Msg,
) -> #(Model, admin_effect.Command(Msg)) {
  let #(page_model, command) = lift_page(transition, wrap_model, wrap_msg)
  #(router_state.new(page_model), command)
}
