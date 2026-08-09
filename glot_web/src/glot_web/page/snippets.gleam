import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_core/snippet/snippet_dto
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

const page_limit = 20

pub type ViewModel {
  ViewModel(
    page: loadable.Loadable(
      pagination_model.CursorPage(snippet_dto.SnippetResponse),
    ),
    username: option.Option(String),
    language: option.Option(language.Language),
    now: Timestamp,
  )
}

pub fn empty_page() -> pagination_model.CursorPage(snippet_dto.SnippetResponse) {
  pagination_model.InitialCursorPage(items: [], next_cursor: option.None)
}

pub fn public_request(
  after after: option.Option(String),
  before before: option.Option(String),
  username username: option.Option(String),
  language language_filter: option.Option(language.Language),
) -> snippet_dto.ListPublicSnippetsRequest {
  snippet_dto.ListPublicSnippetsRequest(
    pagination: pagination_from_cursors(after, before),
    usernames: usernames_from_filter(username),
    languages: languages_from_filter(language_filter),
  )
}

pub fn decoder() -> decode.Decoder(ViewModel) {
  use page <- decode.field(
    "page",
    pagination_model.page_decoder("snippets", snippet_dto.response_decoder()),
  )
  use username <- decode.field("username", decode.optional(decode.string))
  use language_filter <- decode.field(
    "language",
    decode.optional(language.decoder()),
  )
  use now <- decode.field("now", timestamp_helpers.decoder())
  use page <- decode.field("state", state_decoder(page))
  decode.success(ViewModel(page:, username:, language: language_filter, now:))
}

pub fn encode(view_model: ViewModel) -> json.Json {
  let page = loaded_page_or_empty(view_model.page)
  json.object([
    #(
      "page",
      pagination_model.encode_page(
        page,
        "snippets",
        snippet_dto.encode_response,
      ),
    ),
    #("username", json.nullable(view_model.username, json.string)),
    #("language", json.nullable(view_model.language, language.encode)),
    #("now", timestamp_helpers.encode(view_model.now)),
    #("state", encode_state(view_model.page)),
  ])
}

pub fn view(model: ViewModel, show_loading: Bool) -> Element(msg) {
  html.div([attribute.class("app-page")], [
    html.div([attribute.class("app-page__screen-glow")], []),
    html.main(
      [
        attribute.id("main-content"),
        attribute.attribute("tabindex", "-1"),
        attribute.class("app-shell"),
      ],
      [
        html.section([attribute.class("app-panel snippets-page")], [
          html.div([attribute.class("snippets-page__header")], [
            html.div([], [
              html.h1([attribute.class("snippets-page__title")], [
                html.text("Public snippets"),
              ]),
              active_filter_view(model.username, model.language),
            ]),
          ]),
          status_view(model, show_loading),
          content_view(model),
          html.div([attribute.class("snippets-page__pagination")], [
            pagination_button("Previous", previous_page_route(model)),
            pagination_button("Next", next_page_route(model)),
          ]),
        ]),
      ],
    ),
  ])
}

fn pagination_from_cursors(
  after: option.Option(String),
  before: option.Option(String),
) -> pagination_model.CursorPagination {
  case after, before {
    option.Some(cursor), option.None ->
      pagination_model.AfterPage(
        cursor: pagination_model.from_string(cursor),
        limit: page_limit,
      )
    option.None, option.Some(cursor) ->
      pagination_model.BeforePage(
        cursor: pagination_model.from_string(cursor),
        limit: page_limit,
      )
    option.None, option.None -> pagination_model.InitialPage(limit: page_limit)
    option.Some(_), option.Some(_) ->
      pagination_model.InitialPage(limit: page_limit)
  }
}

fn state_decoder(
  page: pagination_model.CursorPage(snippet_dto.SnippetResponse),
) -> decode.Decoder(
  loadable.Loadable(pagination_model.CursorPage(snippet_dto.SnippetResponse)),
) {
  use kind <- decode.field("kind", decode.string)
  case kind {
    "loading" -> decode.success(loadable.Loading)
    "ready" -> decode.success(loadable.Loaded(page))
    "error" -> {
      use message <- decode.field("message", decode.string)
      decode.success(loadable.LoadError(message))
    }
    _ -> decode.failure(loadable.Loading, "SnippetsPageState")
  }
}

fn encode_state(state: loadable.Loadable(a)) -> json.Json {
  case state {
    loadable.NotLoaded | loadable.Loading ->
      json.object([#("kind", json.string("loading"))])
    loadable.Loaded(_) -> json.object([#("kind", json.string("ready"))])
    loadable.LoadError(message) ->
      json.object([
        #("kind", json.string("error")),
        #("message", json.string(message)),
      ])
  }
}

fn previous_page_route(model: ViewModel) -> option.Option(route.Route) {
  case pagination_model.previous_cursor(loaded_page_or_empty(model.page)) {
    option.Some(previous_cursor) ->
      option.Some(
        route.Public(route.Snippets(
          after: option.None,
          before: option.Some(pagination_model.to_string(previous_cursor)),
          username: model.username,
          language: option.map(model.language, language.to_string),
        )),
      )
    option.None -> option.None
  }
}

fn next_page_route(model: ViewModel) -> option.Option(route.Route) {
  case pagination_model.next_cursor(loaded_page_or_empty(model.page)) {
    option.Some(next_cursor) ->
      option.Some(
        route.Public(route.Snippets(
          after: option.Some(pagination_model.to_string(next_cursor)),
          before: option.None,
          username: model.username,
          language: option.map(model.language, language.to_string),
        )),
      )
    option.None -> option.None
  }
}

fn status_view(model: ViewModel, show_loading: Bool) -> Element(msg) {
  case model.page, show_loading {
    loadable.Loading, True ->
      html.p(
        [
          attribute.class("snippets-page__status"),
          attribute.attribute("role", "status"),
        ],
        [html.text("Loading snippets...")],
      )
    loadable.NotLoaded, _ | loadable.Loading, False | loadable.Loaded(_), _ ->
      html.p([attribute.class("snippets-page__status")], [])
    loadable.LoadError(message), _ ->
      html.p(
        [
          attribute.class("snippets-page__status snippets-page__status--error"),
          attribute.attribute("role", "alert"),
        ],
        [html.text(message)],
      )
  }
}

fn content_view(model: ViewModel) -> Element(msg) {
  case model.page {
    loadable.Loaded(page) ->
      case pagination_model.items(page) {
        [] -> empty_state("No public snippets found.")
        snippets ->
          snippets_table(snippets, model.username, model.language, model.now)
      }
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) ->
      html.div([attribute.class("snippets-page__content")], [])
  }
}

fn empty_state(message: String) -> Element(msg) {
  html.div(
    [
      attribute.class("snippets-page__empty"),
      attribute.attribute("role", "status"),
    ],
    [html.p([], [html.text(message)])],
  )
}

fn loaded_page_or_empty(
  state: loadable.Loadable(
    pagination_model.CursorPage(snippet_dto.SnippetResponse),
  ),
) -> pagination_model.CursorPage(snippet_dto.SnippetResponse) {
  case state {
    loadable.Loaded(page) -> page
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) ->
      empty_page()
  }
}

fn active_filter_view(
  username: option.Option(String),
  language_filter: option.Option(language.Language),
) -> Element(msg) {
  case username, language_filter {
    option.None, option.None -> html.div([], [])
    _, _ ->
      html.div([attribute.class("snippets-page__filters")], [
        html.span([attribute.class("snippets-page__filter")], [
          html.text(filter_label(username, language_filter)),
        ]),
        html.a(
          [
            attribute.class("snippets-page__filter-clear"),
            web_route.href(
              route.Public(route.Snippets(
                after: option.None,
                before: option.None,
                username: option.None,
                language: option.None,
              )),
            ),
          ],
          [html.text("Clear")],
        ),
      ])
  }
}

fn filter_label(
  username: option.Option(String),
  language_filter: option.Option(language.Language),
) -> String {
  case username, language_filter {
    option.Some(username), option.Some(lang) ->
      "Filtered by @"
      <> truncate_username(username)
      <> " and "
      <> language.name(lang)
    option.Some(username), option.None ->
      "Filtered by @" <> truncate_username(username)
    option.None, option.Some(lang) -> "Filtered by " <> language.name(lang)
    option.None, option.None -> ""
  }
}

fn snippets_table(
  snippets: List(snippet_dto.SnippetResponse),
  username: option.Option(String),
  language_filter: option.Option(language.Language),
  now: Timestamp,
) -> Element(msg) {
  html.table([attribute.class("snippets-table")], [
    html.caption([attribute.class("visually-hidden")], [
      html.text("Public snippets"),
    ]),
    html.thead([], [
      html.tr([attribute.class("snippets-table__head")], [
        html.th(
          [attribute.class("snippets-table__heading"), attribute.scope("col")],
          [
            html.text("Language"),
          ],
        ),
        html.th(
          [attribute.class("snippets-table__heading"), attribute.scope("col")],
          [
            html.text("Title"),
          ],
        ),
        html.th(
          [attribute.class("snippets-table__heading"), attribute.scope("col")],
          [
            html.text("Created"),
          ],
        ),
        html.th(
          [attribute.class("snippets-table__heading"), attribute.scope("col")],
          [
            html.text("Username"),
          ],
        ),
      ]),
    ]),
    html.tbody([attribute.class("snippets-table__body")], {
      snippets
      |> list.map(fn(snippet) {
        snippet_row(snippet, username, language_filter, now)
      })
    }),
  ])
}

fn snippet_row(
  snippet: snippet_dto.SnippetResponse,
  username: option.Option(String),
  language_filter: option.Option(language.Language),
  now: Timestamp,
) -> Element(msg) {
  html.tr([attribute.class("snippets-table__row")], [
    filter_cell_link(
      "snippets-table__cell snippets-table__cell--language",
      "Language",
      "Filter by language " <> language.name(snippet.data.language),
      route.Public(route.Snippets(
        after: option.None,
        before: option.None,
        username: username,
        language: option.Some(language.to_string(snippet.data.language)),
      )),
      language.name(snippet.data.language),
    ),
    snippet_cell_link(
      "snippets-table__cell snippets-table__cell--title",
      "Title",
      route.Public(route.Snippet(snippet.slug)),
      snippet.data.title,
    ),
    snippet_cell_link(
      "snippets-table__cell",
      "Created",
      route.Public(route.Snippet(snippet.slug)),
      timestamp_helpers.relative_label(snippet.created_at, now),
    ),
    html.td(
      [
        attribute.class("snippets-table__cell"),
      ],
      [
        html.a(
          [
            attribute.class(
              "snippets-table__cell-link snippets-table__username",
            ),
            attribute.attribute(
              "aria-label",
              "Filter by user " <> snippet.user.username,
            ),
            web_route.href(
              route.Public(route.Snippets(
                after: option.None,
                before: option.None,
                username: option.Some(snippet.user.username),
                language: option.map(language_filter, language.to_string),
              )),
            ),
          ],
          [
            html.span([attribute.class("snippets-table__cell-label")], [
              html.text("Username"),
            ]),
            html.span([attribute.class("snippets-table__cell-value")], [
              html.text(truncate_username(snippet.user.username)),
            ]),
          ],
        ),
      ],
    ),
  ])
}

fn snippet_cell_link(
  class_name: String,
  cell_label: String,
  destination: route.Route,
  value: String,
) -> Element(msg) {
  html.td([attribute.class(class_name)], [
    html.a(
      [
        attribute.class("snippets-table__cell-link"),
        web_route.href(destination),
      ],
      [
        html.span([attribute.class("snippets-table__cell-label")], [
          html.text(cell_label),
        ]),
        html.span([attribute.class("snippets-table__cell-value")], [
          html.text(value),
        ]),
      ],
    ),
  ])
}

fn filter_cell_link(
  class_name: String,
  cell_label: String,
  aria_label: String,
  destination: route.Route,
  value: String,
) -> Element(msg) {
  html.td([attribute.class(class_name)], [
    html.a(
      [
        attribute.class("snippets-table__cell-link"),
        attribute.attribute("aria-label", aria_label),
        web_route.href(destination),
      ],
      [
        html.span([attribute.class("snippets-table__cell-label")], [
          html.text(cell_label),
        ]),
        html.span([attribute.class("snippets-table__cell-value")], [
          html.text(value),
        ]),
      ],
    ),
  ])
}

fn pagination_button(
  label: String,
  destination: option.Option(route.Route),
) -> Element(msg) {
  case destination {
    option.Some(destination) ->
      html.a(
        [attribute.class("snippets-page__button"), web_route.href(destination)],
        [html.text(label)],
      )
    option.None ->
      html.button(
        [
          attribute.type_("button"),
          attribute.class("snippets-page__button"),
          attribute.disabled(True),
        ],
        [html.text(label)],
      )
  }
}

fn usernames_from_filter(username: option.Option(String)) -> List(String) {
  case username {
    option.Some(username) -> [username]
    option.None -> []
  }
}

fn languages_from_filter(
  language_filter: option.Option(language.Language),
) -> List(language.Language) {
  case language_filter {
    option.Some(lang) -> [lang]
    option.None -> []
  }
}

fn truncate_username(username: String) -> String {
  truncate_stem_middle(username, 20)
}

fn truncate_stem_middle(stem: String, max_length: Int) -> String {
  case string.length(stem) > max_length {
    False -> stem
    True ->
      case max_length <= 4 {
        True -> string.slice(stem, 0, max_length)
        False -> {
          let visible_length = max_length - 3
          let prefix_length = visible_length - visible_length / 2
          let suffix_length = visible_length / 2

          string.slice(stem, 0, prefix_length)
          <> "..."
          <> string.slice(stem, -suffix_length, string.length(stem))
        }
      }
  }
}
