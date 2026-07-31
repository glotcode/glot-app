import gleam/int
import gleam/result
import glot_core/admin/cleanup_config_dto
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

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

pub type Model =
  section.FormModel(Fields)

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

pub type Msg {
  Loaded(
    Generation(section.LoadStream),
    api_response.Response(cleanup_config_dto.CleanupConfigResponse),
  )
  FieldChanged(Field, String)
  ResetClicked
  SaveClicked
  SaveFinished(
    Generation(section.SaveStream),
    api_response.Response(cleanup_config_dto.CleanupConfigResponse),
  )
}

pub fn init() -> Model {
  section.init(Fields("", "", "", "", "", "", "", ""))
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.load_state {
    section.NotLoaded -> #(
      section.begin_load(model),
      admin_effect.get_admin_cleanup_config(fn(result) {
        Loaded(request_generation.next(model.load_generation), result)
      }),
    )
    section.Loading | section.Ready | section.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    Loaded(generation, _) if generation != model.load_generation -> #(
      model,
      admin_effect.none(),
    )
    Loaded(_, result) ->
      case result {
        api_response.Success(response) -> #(
          section.loaded(model, from_response(response)),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          section.load_failed(model, api_response.error_message(error)),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          section.load_failed(model, "Could not load cleanup config."),
          admin_effect.none(),
        )
      }
    FieldChanged(field, value) -> #(
      section.edit(model, fn(fields) { set(fields, field, value) }),
      admin_effect.none(),
    )
    ResetClicked -> #(section.reset(model), admin_effect.none())
    SaveClicked ->
      case request(model.draft) {
        Ok(request) -> #(
          section.begin_save(model),
          admin_effect.upsert_admin_cleanup_config(request, fn(result) {
            SaveFinished(request_generation.next(model.save_generation), result)
          }),
        )
        Error(message) -> #(
          section.save_failed(model, message),
          admin_effect.none(),
        )
      }
    SaveFinished(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    SaveFinished(_, result) ->
      case result {
        api_response.Success(response) -> #(
          section.saved(model, from_response(response)),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) -> #(
          section.save_failed(model, api_response.error_message(error)),
          admin_effect.none(),
        )
        api_response.HttpFailure(_) -> #(
          section.save_failed(model, "Could not save cleanup config."),
          admin_effect.none(),
        )
      }
  }
}

fn set(fields: Fields, field: Field, value: String) -> Fields {
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

fn from_response(response: cleanup_config_dto.CleanupConfigResponse) -> Fields {
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

fn positive(value: String, label: String) -> Result(Int, String) {
  admin_format.parse_positive_int_with_error(
    value,
    label <> " must be a positive integer.",
  )
}

fn request(
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
