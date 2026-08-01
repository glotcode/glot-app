import gleam/option
import glot_core/admin/job_log_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/cursor_request
import youid/uuid

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(job_log_dto.JobLogResponse),
    ),
    error_filter: job_log_dto.JobLogErrorFilter,
    request_id_filter: String,
    job_id_filter: String,
    applied_request_id_filter: option.Option(uuid.Uuid),
    applied_job_id_filter: option.Option(uuid.Uuid),
    request_id_error: option.Option(String),
    job_id_error: option.Option(String),
    request_generation: cursor_request.State,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
