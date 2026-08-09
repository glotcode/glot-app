import glot_frontend/admin/analytics/message as admin_analytics_page
import glot_frontend/admin/api_logs/detail_message as admin_api_log_page
import glot_frontend/admin/api_logs/list_message as admin_api_logs_page
import glot_frontend/admin/config/page_message as admin_config_page
import glot_frontend/admin/email_templates/detail_message as admin_email_template_page
import glot_frontend/admin/email_templates/list_message as admin_email_templates_page
import glot_frontend/admin/home/page as admin_page
import glot_frontend/admin/job_logs/detail_message as admin_job_log_page
import glot_frontend/admin/job_logs/list_message as admin_job_logs_page
import glot_frontend/admin/jobs/list_message as admin_jobs_page
import glot_frontend/admin/jobs/message as admin_job_page
import glot_frontend/admin/jobs/policies_message as admin_job_type_policies_page
import glot_frontend/admin/periodic_jobs/list_message as admin_periodic_jobs_page
import glot_frontend/admin/periodic_jobs/message as admin_periodic_job_page
import glot_frontend/admin/rate_limits/message as admin_rate_limits_page
import glot_frontend/admin/run_logs/detail_message as admin_run_log_page
import glot_frontend/admin/run_logs/list_message as admin_run_logs_page
import glot_frontend/admin/snippets/detail_message as admin_snippet_page
import glot_frontend/admin/snippets/list_message as admin_snippets_page
import glot_frontend/admin/users/list_message as admin_users_page
import glot_frontend/admin/users/message as admin_user_page

pub type Msg {
  AdminPageMsg(admin_page.Msg)
  AdminAnalyticsPageMsg(admin_analytics_page.Msg)
  AdminApiLogsPageMsg(admin_api_logs_page.Msg)
  AdminApiLogPageMsg(admin_api_log_page.Msg)
  AdminRunLogsPageMsg(admin_run_logs_page.Msg)
  AdminRunLogPageMsg(admin_run_log_page.Msg)
  AdminPeriodicJobsPageMsg(admin_periodic_jobs_page.Msg)
  AdminPeriodicJobPageMsg(admin_periodic_job_page.Msg)
  AdminUsersPageMsg(admin_users_page.Msg)
  AdminUserPageMsg(admin_user_page.Msg)
  AdminJobsPageMsg(admin_jobs_page.Msg)
  AdminJobPageMsg(admin_job_page.Msg)
  AdminEmailTemplatesPageMsg(admin_email_templates_page.Msg)
  AdminEmailTemplatePageMsg(admin_email_template_page.Msg)
  AdminSnippetsPageMsg(admin_snippets_page.Msg)
  AdminSnippetPageMsg(admin_snippet_page.Msg)
  AdminJobLogsPageMsg(admin_job_logs_page.Msg)
  AdminJobLogPageMsg(admin_job_log_page.Msg)
  AdminConfigPageMsg(admin_config_page.Msg)
  AdminRateLimitsPageMsg(admin_rate_limits_page.Msg)
  AdminJobTypePoliciesPageMsg(admin_job_type_policies_page.Msg)
}
