import gleam/list
import gleam/option
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_frontend/ui/delayed_loading

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(snippet_dto.SnippetResponse),
    ),
    after: option.Option(String),
    before: option.Option(String),
    language: option.Option(language.Language),
    pending_delete: option.Option(snippet_dto.SnippetResponse),
    deleting_slug: option.Option(String),
    mutation_error: option.Option(String),
    request: Request,
    loading_indicator: delayed_loading.State,
  )
}

pub opaque type Request {
  Request(
    after: option.Option(String),
    before: option.Option(String),
    language: option.Option(language.Language),
  )
}

pub fn request(
  after after: option.Option(String),
  before before: option.Option(String),
  language language_filter: option.Option(language.Language),
) -> Request {
  Request(after:, before:, language: language_filter)
}

pub fn request_after(request: Request) -> option.Option(String) {
  request.after
}

pub fn request_before(request: Request) -> option.Option(String) {
  request.before
}

pub fn request_language(request: Request) -> option.Option(language.Language) {
  request.language
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
  || delayed_loading.is_visible(model.loading_indicator)
}

pub fn previous_cursor(model: Model) -> option.Option(pagination_model.Cursor) {
  case model.page {
    loadable.Loaded(page) -> pagination_model.previous_cursor(page)
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> option.None
  }
}

pub fn next_cursor(model: Model) -> option.Option(pagination_model.Cursor) {
  case model.page {
    loadable.Loaded(page) -> pagination_model.next_cursor(page)
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> option.None
  }
}

pub fn can_go_previous(model: Model) -> Bool {
  case previous_cursor(model), model.deleting_slug {
    option.Some(_), option.None -> True
    _, _ -> False
  }
}

pub fn can_go_next(model: Model) -> Bool {
  case next_cursor(model), model.deleting_slug {
    option.Some(_), option.None -> True
    _, _ -> False
  }
}

pub fn find_loaded_snippet(
  model: Model,
  slug: String,
) -> option.Option(snippet_dto.SnippetResponse) {
  case model.page {
    loadable.Loaded(page) ->
      page
      |> pagination_model.items
      |> list.find(fn(snippet) { snippet.slug == slug })
      |> option.from_result
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> option.None
  }
}
