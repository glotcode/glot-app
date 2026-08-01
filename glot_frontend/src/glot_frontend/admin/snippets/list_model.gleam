import glot_core/admin/snippet_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/cursor_request

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(snippet_dto.SnippetSummaryResponse),
    ),
    username_filter: String,
    request_generation: cursor_request.State,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
