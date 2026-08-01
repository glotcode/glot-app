import gleam/option
import glot_core/admin/job_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/cursor_request

pub type Model {
  Model(
    page: loadable.Loadable(pagination_model.CursorPage(job_dto.JobResponse)),
    summary: job_dto.JobsSummary,
    status_filter: job_dto.StatusFilter,
    job_type_filter: option.Option(String),
    request_generation: cursor_request.State,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
