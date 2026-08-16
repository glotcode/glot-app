import glot_core/admin/snippet_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/list_query

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(snippet_dto.SnippetSummaryResponse),
    ),
    username_filter: String,
    spam_classification_filter: String,
    query: list_query.Query,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
