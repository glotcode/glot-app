import glot_frontend/admin/analytics/model as admin_analytics_page
import glot_frontend/admin/api_logs/detail_model as admin_api_log_page
import glot_frontend/admin/api_logs/list_model as admin_api_logs_page
import glot_frontend/admin/config/page_model as admin_config_page
import glot_frontend/admin/email_templates/detail_model as admin_email_template_page
import glot_frontend/admin/email_templates/list_model as admin_email_templates_page
import glot_frontend/admin/home/page as admin_page
import glot_frontend/admin/job_logs/detail_model as admin_job_log_page
import glot_frontend/admin/job_logs/list_model as admin_job_logs_page
import glot_frontend/admin/jobs/list_model as admin_jobs_page
import glot_frontend/admin/jobs/model as admin_job_page
import glot_frontend/admin/jobs/policies_model as admin_job_type_policies_page
import glot_frontend/admin/periodic_jobs/list_model as admin_periodic_jobs_page
import glot_frontend/admin/periodic_jobs/model as admin_periodic_job_page
import glot_frontend/admin/rate_limits/model as admin_rate_limits_page
import glot_frontend/admin/run_logs/detail_model as admin_run_log_page
import glot_frontend/admin/run_logs/list_model as admin_run_logs_page
import glot_frontend/admin/snippets/detail_model as admin_snippet_page
import glot_frontend/admin/snippets/list_model as admin_snippets_page
import glot_frontend/admin/users/list_model as admin_users_page
import glot_frontend/admin/users/model as admin_user_page

pub opaque type Model {
  Model(page_model: PageModel)
}

pub type PageModel {
  AdminPage(admin_page.Model)
  AdminAnalyticsPage(admin_analytics_page.Model)
  AdminApiLogsPage(admin_api_logs_page.Model)
  AdminApiLogPage(admin_api_log_page.Model)
  AdminRunLogsPage(admin_run_logs_page.Model)
  AdminRunLogPage(admin_run_log_page.Model)
  AdminPeriodicJobsPage(admin_periodic_jobs_page.Model)
  AdminPeriodicJobPage(admin_periodic_job_page.Model)
  AdminUsersPage(admin_users_page.Model)
  AdminUserPage(admin_user_page.Model)
  AdminJobsPage(admin_jobs_page.Model)
  AdminJobPage(admin_job_page.Model)
  AdminEmailTemplatesPage(admin_email_templates_page.Model)
  AdminEmailTemplatePage(admin_email_template_page.Model)
  AdminSnippetsPage(admin_snippets_page.Model)
  AdminSnippetPage(admin_snippet_page.Model)
  AdminJobLogsPage(admin_job_logs_page.Model)
  AdminJobLogPage(admin_job_log_page.Model)
  AdminConfigPage(admin_config_page.Model)
  AdminRateLimitsPage(admin_rate_limits_page.Model)
  AdminJobTypePoliciesPage(admin_job_type_policies_page.Model)
  EmptyPageModel
}

pub fn new(page_model: PageModel) -> Model {
  Model(page_model)
}

pub fn page(model: Model) -> PageModel {
  model.page_model
}

pub fn is_presentable(model: Model) -> Bool {
  case page(model) {
    AdminPage(_) | EmptyPageModel -> True
    AdminAnalyticsPage(model) -> admin_analytics_page.is_presentable(model)
    AdminApiLogsPage(model) -> admin_api_logs_page.is_presentable(model)
    AdminApiLogPage(model) -> admin_api_log_page.is_presentable(model)
    AdminRunLogsPage(model) -> admin_run_logs_page.is_presentable(model)
    AdminRunLogPage(model) -> admin_run_log_page.is_presentable(model)
    AdminPeriodicJobsPage(model) ->
      admin_periodic_jobs_page.is_presentable(model)
    AdminPeriodicJobPage(model) -> admin_periodic_job_page.is_presentable(model)
    AdminUsersPage(model) -> admin_users_page.is_presentable(model)
    AdminUserPage(model) -> admin_user_page.is_presentable(model)
    AdminJobsPage(model) -> admin_jobs_page.is_presentable(model)
    AdminJobPage(model) -> admin_job_page.is_presentable(model)
    AdminEmailTemplatesPage(model) ->
      admin_email_templates_page.is_presentable(model)
    AdminEmailTemplatePage(model) ->
      admin_email_template_page.is_presentable(model)
    AdminSnippetsPage(model) -> admin_snippets_page.is_presentable(model)
    AdminSnippetPage(model) -> admin_snippet_page.is_presentable(model)
    AdminJobLogsPage(model) -> admin_job_logs_page.is_presentable(model)
    AdminJobLogPage(model) -> admin_job_log_page.is_presentable(model)
    AdminConfigPage(model) -> admin_config_page.is_presentable(model)
    AdminRateLimitsPage(model) -> admin_rate_limits_page.is_presentable(model)
    AdminJobTypePoliciesPage(model) ->
      admin_job_type_policies_page.is_presentable(model)
  }
}
