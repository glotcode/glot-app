import gleam/option
import glot_core/admin/run_log_dto
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/list_query
import youid/uuid

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(run_log_dto.RunLogResponse),
    ),
    outcome_filter: run_log_dto.RunLogOutcomeFilter,
    request_id_filter: String,
    session_id_filter: String,
    user_id_filter: String,
    language_filter: String,
    applied_request_id_filter: option.Option(uuid.Uuid),
    applied_session_id_filter: option.Option(uuid.Uuid),
    applied_user_id_filter: option.Option(uuid.Uuid),
    applied_language_filter: option.Option(language.Language),
    request_id_error: option.Option(String),
    session_id_error: option.Option(String),
    user_id_error: option.Option(String),
    language_error: option.Option(String),
    query: list_query.Query,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
