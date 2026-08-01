import gleam/option
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_frontend/ui/delayed_loading

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(snippet_dto.SnippetResponse),
    ),
    username: option.Option(String),
    request: Request,
    loading_indicator: delayed_loading.State,
  )
}

pub type Request {
  Request(
    after: option.Option(String),
    before: option.Option(String),
    username: option.Option(String),
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
  || delayed_loading.is_visible(model.loading_indicator)
}
