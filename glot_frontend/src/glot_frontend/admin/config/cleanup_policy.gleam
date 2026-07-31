import gleam/int
import gleam/result
import glot_core/admin/cleanup_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    api_log_retention_days: String,
    page_log_retention_days: String,
    pageview_log_retention_days: String,
    run_log_retention_days: String,
    job_log_retention_days: String,
    jobs_retention_days: String,
    login_tokens_retention_days: String,
    user_actions_retention_days: String,
  )
}

pub type Field {
  ApiLog
  PageLog
  PageviewLog
  RunLog
  JobLog
  Jobs
  LoginTokens
  UserActions
}

pub fn initial() -> Fields {
  Fields("", "", "", "", "", "", "", "")
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    ApiLog -> Fields(..fields, api_log_retention_days: value)
    PageLog -> Fields(..fields, page_log_retention_days: value)
    PageviewLog -> Fields(..fields, pageview_log_retention_days: value)
    RunLog -> Fields(..fields, run_log_retention_days: value)
    JobLog -> Fields(..fields, job_log_retention_days: value)
    Jobs -> Fields(..fields, jobs_retention_days: value)
    LoginTokens -> Fields(..fields, login_tokens_retention_days: value)
    UserActions -> Fields(..fields, user_actions_retention_days: value)
  }
}

pub fn from_response(
  response: cleanup_config_dto.CleanupConfigResponse,
) -> Fields {
  Fields(
    api_log_retention_days: int.to_string(response.api_log_retention_days),
    page_log_retention_days: int.to_string(response.page_log_retention_days),
    pageview_log_retention_days: int.to_string(
      response.pageview_log_retention_days,
    ),
    run_log_retention_days: int.to_string(response.run_log_retention_days),
    job_log_retention_days: int.to_string(response.job_log_retention_days),
    jobs_retention_days: int.to_string(response.jobs_retention_days),
    login_tokens_retention_days: int.to_string(
      response.login_tokens_retention_days,
    ),
    user_actions_retention_days: int.to_string(
      response.user_actions_retention_days,
    ),
  )
}

pub fn request(
  fields: Fields,
) -> Result(cleanup_config_dto.UpsertCleanupConfigRequest, String) {
  use api_log_retention_days <- result.try(positive(
    fields.api_log_retention_days,
    "API log retention",
  ))
  use page_log_retention_days <- result.try(positive(
    fields.page_log_retention_days,
    "Page log retention",
  ))
  use pageview_log_retention_days <- result.try(positive(
    fields.pageview_log_retention_days,
    "Pageview log retention",
  ))
  use run_log_retention_days <- result.try(positive(
    fields.run_log_retention_days,
    "Run log retention",
  ))
  use job_log_retention_days <- result.try(positive(
    fields.job_log_retention_days,
    "Job log retention",
  ))
  use jobs_retention_days <- result.try(positive(
    fields.jobs_retention_days,
    "Jobs retention",
  ))
  use login_tokens_retention_days <- result.try(positive(
    fields.login_tokens_retention_days,
    "Login token retention",
  ))
  use user_actions_retention_days <- result.try(positive(
    fields.user_actions_retention_days,
    "User actions retention",
  ))
  Ok(cleanup_config_dto.UpsertCleanupConfigRequest(
    api_log_retention_days:,
    page_log_retention_days:,
    pageview_log_retention_days:,
    run_log_retention_days:,
    job_log_retention_days:,
    jobs_retention_days:,
    login_tokens_retention_days:,
    user_actions_retention_days:,
  ))
}

fn positive(value: String, label: String) -> Result(Int, String) {
  admin_format.parse_positive_int_with_error(
    value,
    label <> " must be a positive integer.",
  )
}
