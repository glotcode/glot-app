import gleam/int
import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/admin/snippet_dto
import glot_core/helpers/timestamp_helpers
import glot_core/language
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/snippets/list_message.{
  type Msg, ApplyFilterClicked, ClearFilterClicked, NextPageClicked,
  PreviousPageClicked, UsernameFilterChanged,
}
import glot_frontend/admin/snippets/list_model.{type Model}
import glot_frontend/admin/snippets/route as snippets_route
import glot_frontend/admin/ui/cursor_page as admin_cursor_page
import glot_frontend/admin/ui/filter as admin_filter
import glot_frontend/admin/ui/form as admin_form
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/pagination as admin_pagination
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/ui/table as admin_table
import glot_frontend/ui/string_helpers
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

const title_max_length = 32

const owner_max_length = 20

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  let rows = pagination_model.items(current_page(model))
  let count_text = int.to_string(list.length(rows)) <> " snippets shown."

  admin_layout.page_with_panel_class(
    panel_class: "admin-jobs-page",
    title: "Snippets",
    intro: "",
    actions: admin_pagination.cursor_pagination_actions(
      current_page(model),
      PreviousPageClicked,
      NextPageClicked,
    ),
    content: [
      admin_filter.filter_section(
        copy: "Filter snippets by exact username.",
        content: admin_filter.filter_surface(
          [attribute.class("admin-snippets-page__filters")],
          [
            admin_filter.filter_field_grid([], [
              admin_form.text_input(
                label: "Username",
                help: "Matches an exact account username.",
                value: model.username_filter,
                placeholder: "username",
                on_input: UsernameFilterChanged,
              ),
            ]),
            admin_filter.filter_actions([], [
              html.button(
                [
                  attribute.class("admin-page__button"),
                  attribute.type_("button"),
                  event.on_click(ApplyFilterClicked),
                ],
                [html.text("Apply")],
              ),
              admin_layout.secondary_button(
                [
                  attribute.type_("button"),
                  attribute.disabled(model.username_filter == ""),
                  event.on_click(ClearFilterClicked),
                ],
                "Clear",
              ),
            ]),
          ],
        ),
      ),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.div([], [
            html.h3([attribute.class("admin-page__group-title")], [
              html.text("Directory"),
            ]),
            html.p([attribute.class("admin-page__group-copy")], [
              html.text(count_text),
            ]),
          ]),
        ]),
        admin_status.loadable_status(model.page, "Loading snippets..."),
        snippets_table(model, now),
      ]),
    ],
  )
}

fn snippets_table(model: Model, now: Timestamp) -> Element(Msg) {
  admin_pagination.loadable_cursor_page_content(
    model.page,
    "Loading snippets...",
    "No snippets were returned.",
    fn(rows) {
      admin_table.table(snippet_columns(), {
        rows |> list.map(fn(snippet) { snippet_row(snippet, now) })
      })
    },
  )
}

fn current_page(
  model: Model,
) -> pagination_model.CursorPage(snippet_dto.SnippetSummaryResponse) {
  admin_cursor_page.current_page(model.page)
}

fn snippet_row(
  snippet: snippet_dto.SnippetSummaryResponse,
  now: Timestamp,
) -> Element(Msg) {
  admin_table.row([
    admin_table.value_cell(slug_column(), snippet.slug),
    admin_table.cell_with(
      language_column(),
      [
        attribute.class("admin-table__cell admin-table__cell--language"),
      ],
      [admin_table.value(language.name(snippet.language))],
    ),
    admin_table.cell_with(
      title_column(),
      [attribute.class("admin-table__cell admin-table__cell--title")],
      [
        admin_table.value(string_helpers.truncate_stem_middle(
          snippet.title,
          title_max_length,
        )),
      ],
    ),
    admin_table.cell(owner_column(), [
      admin_table.primary_link(
        [web_route.href(snippets_route.for_owner(snippet.user.username))],
        string_helpers.truncate_stem_middle(
          snippet.user.username,
          owner_max_length,
        ),
      ),
    ]),
    admin_table.primary_meta_cell(
      updated_column(),
      timestamp_helpers.relative_label(snippet.updated_at, now),
      option.Some(int.to_string(snippet.file_count) <> " files"),
    ),
    admin_table.action_link_cell(
      open_column(),
      [web_route.href(route.Admin(route.AdminSnippet(snippet.slug)))],
      "Details",
    ),
  ])
}

fn snippet_columns() -> List(admin_table.Column) {
  [
    slug_column(),
    language_column(),
    title_column(),
    owner_column(),
    updated_column(),
    open_column(),
  ]
}

fn slug_column() -> admin_table.Column {
  admin_table.column("Slug")
}

fn language_column() -> admin_table.Column {
  admin_table.fit_column("Language")
}

fn title_column() -> admin_table.Column {
  admin_table.column("Title")
}

fn owner_column() -> admin_table.Column {
  admin_table.column("Owner")
}

fn updated_column() -> admin_table.Column {
  admin_table.column("Updated at")
}

fn open_column() -> admin_table.Column {
  admin_table.open_column()
}
