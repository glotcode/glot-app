import glot_frontend/admin/ui/layout as admin_layout
import lustre/element.{type Element}

pub fn job_type_label(job_type: String) -> String {
  case job_type {
    "clean_api_log" -> "Clean API log"
    "clean_page_log" -> "Clean page log"
    "clean_pageview_log" -> "Clean pageview log"
    "clean_run_log" -> "Clean run log"
    "clean_job_log" -> "Clean job log"
    "clean_jobs" -> "Clean jobs"
    "clean_sessions" -> "Clean sessions"
    "clean_login_tokens" -> "Clean verification tokens"
    "clean_user_actions" -> "Clean user actions"
    "aggregate_metrics" -> "Aggregate metrics"
    "classify_snippet" -> "Classify snippet"
    "check_snippet_runnability" -> "Check snippet runnability"
    "delete_account" -> "Delete account"
    "send_email" -> "Send email"
    _ -> job_type
  }
}

pub fn status_text(status: String, overdue: Bool) -> String {
  case status, overdue {
    "pending", True -> "Pending • overdue"
    "pending", False -> "Pending"
    "running", _ -> "Running"
    "failed", _ -> "Failed"
    "done", _ -> "Done"
    value, _ -> value
  }
}

pub fn status_badge(status: String, overdue: Bool) -> Element(msg) {
  case status, overdue {
    "failed", _ ->
      admin_layout.badge(status_text(status, overdue), admin_layout.DangerTone)
    "running", _ ->
      admin_layout.badge(status_text(status, overdue), admin_layout.WarningTone)
    "pending", True ->
      admin_layout.badge(status_text(status, overdue), admin_layout.DangerTone)
    "pending", False ->
      admin_layout.badge(status_text(status, overdue), admin_layout.InfoTone)
    "done", _ ->
      admin_layout.badge(status_text(status, overdue), admin_layout.SuccessTone)
    _, _ ->
      admin_layout.badge(status_text(status, overdue), admin_layout.NeutralTone)
  }
}
