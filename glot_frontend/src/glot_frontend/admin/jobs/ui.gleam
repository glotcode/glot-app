import glot_core/job/job_model.{type JobType}
import glot_frontend/admin/ui/layout as admin_layout
import lustre/element.{type Element}

pub fn job_type_label(value: String) -> String {
  case job_model.job_type_from_string(value) {
    Ok(job_type) -> known_job_type_label(job_type)
    Error(_) -> value
  }
}

// Keep this match exhaustive so new job types require a display label.
fn known_job_type_label(job_type: JobType) -> String {
  case job_type {
    job_model.CleanApiLogJob -> "Clean API log"
    job_model.CleanPageLogJob -> "Clean page log"
    job_model.CleanPageviewLogJob -> "Clean pageview log"
    job_model.CleanRunLogJob -> "Clean run log"
    job_model.CleanJobLogJob -> "Clean job log"
    job_model.CleanJobsJob -> "Clean jobs"
    job_model.CleanSessionsJob -> "Clean sessions"
    job_model.CleanVerificationTokensJob -> "Clean verification tokens"
    job_model.CleanUserActionsJob -> "Clean user actions"
    job_model.AggregateMetricsJob -> "Aggregate metrics"
    job_model.ClassifySnippetJob -> "Classify snippet"
    job_model.IndexSnippetFingerprintsJob -> "Index snippet fingerprints"
    job_model.CheckSnippetRunnabilityJob -> "Check snippet runnability"
    job_model.DeleteAccountJob -> "Delete account"
    job_model.SendEmailJob -> "Send email"
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
