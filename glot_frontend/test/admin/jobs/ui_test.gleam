import glot_frontend/admin/jobs/ui as admin_job_ui

pub fn classifier_job_type_has_a_human_readable_label_test() {
  assert admin_job_ui.job_type_label("classify_snippet") == "Classify snippet"
}

pub fn unknown_job_type_label_preserves_the_identifier_test() {
  assert admin_job_ui.job_type_label("future_job") == "future_job"
}
