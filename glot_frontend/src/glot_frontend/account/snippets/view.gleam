import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/account/snippets/message.{
  type Msg, DeleteCancelled, DeleteClicked, DeleteConfirmed, DeleteDialogClosed,
  NextPageClicked, PreviousPageClicked,
}
import glot_frontend/account/snippets/model as snippets_model
import glot_frontend/ui/delayed_loading
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

const delete_dialog_id = "manage-snippets-page-delete-dialog"

pub fn view(model: snippets_model.Model, now: Timestamp) -> Element(Msg) {
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
                html.text("Your snippets"),
              ]),
              html.p([attribute.class("snippets-page__status")], [
                html.text("Manage snippets created in your account."),
              ]),
              active_filter_view(model.language),
            ]),
          ]),
          status_view(model),
          content_view(model, now),
          html.div([attribute.class("snippets-page__pagination")], [
            pagination_button(
              "Previous",
              PreviousPageClicked,
              snippets_model.can_go_previous(model),
            ),
            pagination_button(
              "Next",
              NextPageClicked,
              snippets_model.can_go_next(model),
            ),
          ]),
        ]),
      ],
    ),
    delete_confirmation_dialog(model),
  ])
}

fn status_view(model: snippets_model.Model) -> Element(Msg) {
  case
    model.mutation_error,
    model.deleting_slug,
    model.page,
    delayed_loading.is_visible(model.loading_indicator)
  {
    option.Some(message), _, _, _ -> error_status(message)
    _, option.Some(_), _, _ -> info_status("Deleting snippet...")
    _, _, loadable.LoadError(message), _ -> error_status(message)
    _, _, loadable.Loading, True -> info_status("Loading your snippets...")
    _, _, loadable.NotLoaded, _
    | _, _, loadable.Loading, False
    | _, _, loadable.Loaded(_), _
    -> info_status("")
  }
}

fn info_status(message: String) -> Element(Msg) {
  html.p(
    [
      attribute.class("snippets-page__status"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-atomic", "true"),
    ],
    [html.text(message)],
  )
}

fn error_status(message: String) -> Element(Msg) {
  html.p(
    [
      attribute.class("snippets-page__status snippets-page__status--error"),
      attribute.attribute("role", "alert"),
      attribute.attribute("aria-atomic", "true"),
    ],
    [html.text(message)],
  )
}

fn content_view(model: snippets_model.Model, now: Timestamp) -> Element(Msg) {
  case model.page {
    loadable.Loaded(page) ->
      case pagination_model.items(page) {
        [] -> empty_state(empty_message(model.language))
        _ -> snippets_table(page, model.deleting_slug, now)
      }
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) ->
      html.div([attribute.class("snippets-page__content")], [])
  }
}

fn empty_message(language_filter: option.Option(language.Language)) -> String {
  case language_filter {
    option.Some(lang) -> "No " <> language.name(lang) <> " snippets found."
    option.None -> "You have not created any snippets yet."
  }
}

fn active_filter_view(
  language_filter: option.Option(language.Language),
) -> Element(Msg) {
  case language_filter {
    option.Some(lang) ->
      html.div([attribute.class("snippets-page__filters")], [
        html.span([attribute.class("snippets-page__filter")], [
          html.text("Filtered by " <> language.name(lang)),
        ]),
        html.a(
          [
            attribute.class("snippets-page__filter-clear"),
            web_route.href(
              route.Account(route.AccountSnippets(
                after: option.None,
                before: option.None,
                language: option.None,
              )),
            ),
          ],
          [html.text("Clear")],
        ),
      ])
    option.None -> html.div([], [])
  }
}

fn empty_state(message: String) -> Element(Msg) {
  html.div(
    [
      attribute.class("snippets-page__empty"),
      attribute.attribute("role", "status"),
    ],
    [html.p([], [html.text(message)])],
  )
}

fn snippets_table(
  page: pagination_model.CursorPage(snippet_dto.SnippetResponse),
  deleting_slug: option.Option(String),
  now: Timestamp,
) -> Element(Msg) {
  html.table([attribute.class("snippets-table snippets-table--manage")], [
    html.caption([attribute.class("visually-hidden")], [
      html.text("Your snippets"),
    ]),
    html.thead([], [
      html.tr(
        [attribute.class("snippets-table__head snippets-table__head--manage")],
        [
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
              html.text("Visibility"),
            ],
          ),
          html.th(
            [attribute.class("snippets-table__heading"), attribute.scope("col")],
            [
              html.text("Updated"),
            ],
          ),
          html.th(
            [attribute.class("snippets-table__heading"), attribute.scope("col")],
            [
              html.text("Actions"),
            ],
          ),
        ],
      ),
    ]),
    html.tbody([attribute.class("snippets-table__body")], {
      pagination_model.items(page)
      |> list.map(fn(snippet) { snippet_row(snippet, deleting_slug, now) })
    }),
  ])
}

fn snippet_row(
  snippet: snippet_dto.SnippetResponse,
  deleting_slug: option.Option(String),
  now: Timestamp,
) -> Element(Msg) {
  let is_deleting = deleting_slug == option.Some(snippet.slug)

  html.tr([attribute.class("snippets-table__row snippets-table__row--manage")], [
    filter_cell_link(
      "snippets-table__cell snippets-table__cell--language",
      "Language",
      "Filter by language " <> language.name(snippet.data.language),
      route.Account(route.AccountSnippets(
        after: option.None,
        before: option.None,
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
    html.td([attribute.class("snippets-table__cell")], [
      html.span([attribute.class("snippets-table__cell-label")], [
        html.text("Visibility"),
      ]),
      html.span([attribute.class("snippets-table__cell-value")], [
        html.text(snippet_model.visibility_to_string(snippet.data.visibility)),
      ]),
    ]),
    snippet_cell_link(
      "snippets-table__cell",
      "Updated",
      route.Public(route.Snippet(snippet.slug)),
      timestamp_helpers.relative_label(snippet.updated_at, now),
    ),
    html.td([attribute.class("snippets-table__cell snippets-table__actions")], [
      html.span([attribute.class("snippets-table__cell-label")], [
        html.text("Actions"),
      ]),
      html.div([attribute.class("snippets-table__action-group")], [
        html.a(
          [
            attribute.class("snippets-table__action-link"),
            web_route.href(route.Public(route.Snippet(snippet.slug))),
          ],
          [html.text("Edit")],
        ),
        html.button(
          [
            attribute.type_("button"),
            attribute.class("snippets-table__action-button"),
            attribute.disabled(is_deleting),
            event.on_click(DeleteClicked(snippet.slug)),
          ],
          [
            html.text(case is_deleting {
              True -> "Deleting..."
              False -> "Delete"
            }),
          ],
        ),
      ]),
    ]),
  ])
}

fn filter_cell_link(
  class_name: String,
  cell_label: String,
  aria_label: String,
  destination: route.Route,
  value: String,
) -> Element(Msg) {
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

fn delete_confirmation_dialog(model: snippets_model.Model) -> Element(Msg) {
  html.dialog(
    [
      attribute.id(delete_dialog_id),
      attribute.class("app-dialog"),
      attribute.attribute("aria-label", "Delete snippet"),
      event.on("close", decode.success(DeleteDialogClosed)),
    ],
    delete_confirmation_dialog_children(model.pending_delete),
  )
}

fn delete_confirmation_dialog_children(
  pending_delete: option.Option(snippet_dto.SnippetResponse),
) -> List(Element(Msg)) {
  case pending_delete {
    option.Some(snippet) -> [
      html.form([attribute.class("app-dialog__form")], [
        html.div([attribute.class("app-dialog__section")], [
          html.p([attribute.class("app-dialog__label")], [
            html.text("Delete snippet"),
          ]),
          html.p([attribute.class("app-dialog__copy")], [
            html.text("Delete "),
            html.code([], [html.text(snippet.data.title)]),
            html.text("? This action cannot be undone."),
          ]),
        ]),
        html.div([attribute.class("app-dialog__actions")], [
          html.button(
            [
              attribute.type_("button"),
              attribute.autofocus(True),
              attribute.class(
                "app-dialog__button app-dialog__button--secondary",
              ),
              event.on_click(DeleteCancelled),
            ],
            [html.text("Cancel")],
          ),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("app-dialog__button app-dialog__button--danger"),
              event.on_click(DeleteConfirmed(snippet.slug)),
            ],
            [html.text("Delete snippet")],
          ),
        ]),
      ]),
    ]
    option.None -> []
  }
}

fn snippet_cell_link(
  class_name: String,
  cell_label: String,
  destination: route.Route,
  value: String,
) -> Element(Msg) {
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

fn pagination_button(label: String, msg: Msg, enabled: Bool) -> Element(Msg) {
  html.button(
    [
      attribute.type_("button"),
      attribute.class("snippets-page__button"),
      attribute.disabled(!enabled),
      event.on_click(msg),
    ],
    [html.text(label)],
  )
}
