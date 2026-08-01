import gleam/option
import glot_core/admin/api_log_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/cursor_request
import youid/uuid

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(api_log_dto.ApiLogSummaryResponse),
    ),
    error_filter: api_log_dto.ApiLogErrorFilter,
    request_id_filter: String,
    applied_request_id_filter: option.Option(uuid.Uuid),
    request_id_error: option.Option(String),
    request_generation: cursor_request.State,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
