import gleam/option
import glot_core/admin/spam_review_dto.{type ReviewSnippet}
import glot_core/loadable
import glot_core/pagination_model.{type CursorPage}
import glot_frontend/admin/spam_review/query.{type Draft}

pub type Undo {
  Undo(item: ReviewSnippet, query: option.Option(String), saved_version: Int)
}

pub type Model {
  Model(
    page: loadable.Loadable(CursorPage(ReviewSnippet)),
    raw_query: option.Option(String),
    applied: Draft,
    draft: Draft,
    generation: Int,
    saving: Bool,
    error: option.Option(String),
    undo: option.Option(Undo),
  )
}

pub fn is_presentable(model: Model) -> Bool {
  case model.page {
    loadable.NotLoaded | loadable.Loading -> False
    _ -> True
  }
}
