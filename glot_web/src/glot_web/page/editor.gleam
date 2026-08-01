import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import glot_core/helpers/timestamp_helpers
import glot_core/helpers/uuid_helpers
import glot_core/language
import glot_core/route
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_web/page/editor_layout
import glot_web/page/icons
import glot_web/page/seo
import glot_web/page/site_chrome
import glot_web/page/top_bar
import lustre/attribute
import lustre/element as lustre_element
import lustre/element/html
import youid/uuid

pub type ViewModel {
  UnsupportedLanguage(language_slug: String)
  LoadError(message: String)
  NewSnippet(EditorModel)
  ExistingSnippet(EditorModel)
}

pub type EditorModel {
  EditorModel(
    slug: option.Option(String),
    owner_user_id: option.Option(uuid.Uuid),
    owner_username: option.Option(String),
    title: String,
    language: language.Language,
    visibility: option.Option(snippet_model.Visibility),
    created_at: option.Option(timestamp.Timestamp),
    updated_at: option.Option(timestamp.Timestamp),
    run_instructions_override: option.Option(language.RunInstructions),
    files: List(snippet_model.File),
    stdin: option.Option(String),
  )
}

pub fn new(language_slug: String) -> ViewModel {
  case language.from_string(language_slug) {
    option.Some(lang) -> NewSnippet(default_editor_model(lang))
    option.None -> UnsupportedLanguage(language_slug)
  }
}

pub fn from_snippet(response: snippet_dto.SnippetResponse) -> ViewModel {
  ExistingSnippet(EditorModel(
    slug: option.Some(response.slug),
    owner_user_id: option.Some(response.user.id),
    owner_username: option.Some(response.user.username),
    title: title_or_default(response.data.title),
    language: response.data.language,
    visibility: option.Some(response.data.visibility),
    created_at: option.Some(response.created_at),
    updated_at: option.Some(response.updated_at),
    run_instructions_override: response.data.run_instructions,
    files: response.data.files,
    stdin: stdin_option(response.data.stdin),
  ))
}

pub fn title(view_model: ViewModel) -> String {
  seo.title(metadata(view_model))
}

pub fn encode(view_model: ViewModel) -> json.Json {
  case view_model {
    UnsupportedLanguage(language_slug) ->
      json.object([
        #("kind", json.string("unsupported")),
        #("languageSlug", json.string(language_slug)),
      ])
    LoadError(message) ->
      json.object([
        #("kind", json.string("error")),
        #("message", json.string(message)),
      ])
    NewSnippet(model) ->
      json.object([
        #("kind", json.string("new")),
        #("editor", encode_editor_model(model)),
      ])
    ExistingSnippet(model) ->
      json.object([
        #("kind", json.string("existing")),
        #("editor", encode_editor_model(model)),
      ])
  }
}

pub fn decoder() -> decode.Decoder(ViewModel) {
  use kind <- decode.field("kind", decode.string)

  case kind {
    "unsupported" -> {
      use language_slug <- decode.field("languageSlug", decode.string)
      decode.success(UnsupportedLanguage(language_slug))
    }
    "error" -> {
      use message <- decode.field("message", decode.string)
      decode.success(LoadError(message))
    }
    "new" -> {
      use editor_model <- decode.field("editor", editor_model_decoder())
      decode.success(NewSnippet(editor_model))
    }
    "existing" -> {
      use editor_model <- decode.field("editor", editor_model_decoder())
      decode.success(ExistingSnippet(editor_model))
    }
    _ -> decode.failure(UnsupportedLanguage(""), "EditorViewModel")
  }
}

pub fn render(view_model: ViewModel) -> lustre_element.Element(Nil) {
  site_chrome.view(
    top_bar_model: top_bar.empty_model(),
    footer_account_route: route.Account(route.AccountHome),
    content: content(view_model),
  )
}

pub fn head_children(
  view_model: ViewModel,
  social_image_url: option.Option(String),
) -> List(lustre_element.Element(Nil)) {
  seo.append(
    seo.head_children(metadata(view_model), social_image_url),
    seo.append(article_meta(view_model), structured_data(view_model)),
  )
}

pub fn metadata(view_model: ViewModel) -> seo.Metadata {
  seo.metadata(
    title: case view_model {
      UnsupportedLanguage(language_slug) ->
        "Unsupported " <> language_slug <> " language | glot.io"
      LoadError(_) -> "Snippet unavailable | glot.io"
      NewSnippet(EditorModel(language:, ..)) ->
        "Run " <> language.name(language) <> " Online | glot.io"
      ExistingSnippet(EditorModel(title:, language:, ..)) ->
        snippet_page_title(title, language.name(language))
    },
    description: description(view_model),
    canonical_path: canonical_path(view_model),
    index: is_indexable(view_model),
    open_graph_type: og_type(view_model),
  )
}

fn is_indexable(view_model: ViewModel) -> Bool {
  case view_model {
    NewSnippet(_) -> True
    ExistingSnippet(EditorModel(visibility: option.Some(visibility), ..)) ->
      visibility == snippet_model.Public
    UnsupportedLanguage(_) | LoadError(_) | ExistingSnippet(_) -> False
  }
}

fn content(view_model: ViewModel) -> lustre_element.Element(Nil) {
  case view_model {
    UnsupportedLanguage(language_slug) ->
      html.div([attribute.class("app-page")], [
        html.div([attribute.class("app-page__screen-glow")], []),
        html.main(
          [
            attribute.id("main-content"),
            attribute.attribute("tabindex", "-1"),
            attribute.class("app-shell app-shell--narrow"),
          ],
          [
            html.section([attribute.class("app-panel")], [
              html.h1([], [html.text("Unsupported language")]),
              html.p([], [
                html.text(
                  "No editor is available for language slug: " <> language_slug,
                ),
              ]),
            ]),
          ],
        ),
      ])
    LoadError(message) ->
      html.div([attribute.class("app-page")], [
        html.div([attribute.class("app-page__screen-glow")], []),
        html.main(
          [
            attribute.id("main-content"),
            attribute.attribute("tabindex", "-1"),
            attribute.class("app-shell app-shell--narrow"),
          ],
          [
            html.section([attribute.class("app-panel")], [
              html.h1([], [html.text("Snippet unavailable")]),
              html.p([], [html.text(message)]),
            ]),
          ],
        ),
      ])
    NewSnippet(model) | ExistingSnippet(model) ->
      content_for_model(model, view_model)
  }
}

fn content_for_model(
  model: EditorModel,
  view_model: ViewModel,
) -> lustre_element.Element(Nil) {
  editor_layout.shell(
    load_ad: False,
    title: model.title,
    title_actions: [
      title_info_button(view_model),
      title_edit_button(view_model),
    ],
    pre_tabbar_children: [metadata_panel(model)],
    tabbar_children: tabbar_children(model),
    active_tab_id: "editor-file-tab-0",
    editor: lustre_element.element(
      "glot-codemirror",
      [
        attribute.id("editor-page-codemirror"),
        attribute.class("editor-shell__codemirror"),
        attribute.attribute("language", language.to_string(model.language)),
        attribute.attribute("keyboard-bindings", "default"),
      ],
      [code_fallback(model)],
    ),
    action_buttons: [
      action_button("editor-shell__action-button", "Run"),
      action_button("editor-shell__action-button", "Save"),
    ],
    console: console_view(),
  )
}

fn title_info_button(view_model: ViewModel) -> lustre_element.Element(Nil) {
  case view_model {
    ExistingSnippet(_) ->
      editor_layout.title_hint_button(
        class_name: "editor-page__title-edit-button editor-page__title-info-button",
        aria_label: "Snippet info",
        hint_class: "editor-page__title-hint editor-page__title-hint--info",
        hint_label: "Info",
        attributes: [attribute.disabled(True)],
      )
    _ -> html.div([], [])
  }
}

fn title_edit_button(view_model: ViewModel) -> lustre_element.Element(Nil) {
  case view_model {
    NewSnippet(_) ->
      editor_layout.title_hint_button(
        class_name: "editor-page__title-edit-button",
        aria_label: "Edit title",
        hint_class: "editor-page__title-hint",
        hint_label: "Edit",
        attributes: [attribute.disabled(True)],
      )
    _ -> html.div([], [])
  }
}

fn selected_tab_content(model: EditorModel) -> String {
  case model.files, model.stdin {
    [snippet_model.File(content:, ..), ..], _ -> content
    [], option.Some(stdin) -> stdin
    [], option.None -> ""
  }
}

fn code_fallback(model: EditorModel) -> lustre_element.Element(Nil) {
  html.pre([attribute.class("editor-page__ssr-code")], [
    html.code([], [html.text(selected_tab_content(model))]),
  ])
}

fn action_button(
  class_name: String,
  label: String,
) -> lustre_element.Element(Nil) {
  editor_layout.shell_button(
    class_name: class_name,
    attributes: [attribute.disabled(True)],
    children: [html.text(label)],
  )
}

fn console_view() -> lustre_element.Element(Nil) {
  editor_layout.console_shell(
    header: html.div([attribute.class("editor-shell__console-header")], [
      html.text("INFO"),
    ]),
    body: html.div([], []),
  )
}

fn metadata_panel(model: EditorModel) -> lustre_element.Element(Nil) {
  let items = metadata_items(model)

  case items {
    [] -> html.div([], [])
    _ ->
      html.dialog(
        [
          attribute.id("editor-page-snippet-info-dialog"),
          attribute.class("editor-page__dialog"),
          attribute.attribute("aria-label", "Snippet information"),
        ],
        [
          editor_layout.dialog_form([
            editor_layout.dialog_info_heading(),
            html.dl([], items),
          ]),
        ],
      )
  }
}

fn tabbar_children(model: EditorModel) -> List(lustre_element.Element(Nil)) {
  [
    icon_button("editor-shell__settings-button", "Editor settings", [
      icons.cog_6_tooth(),
    ]),
    editor_layout.tab_scroll(tab_views(model)),
    meta_button(),
    icon_button("editor-shell__tab-action-button", "Add editor entry", [
      icons.document_plus(),
    ]),
  ]
}

fn icon_button(
  class_name: String,
  aria_label: String,
  children: List(lustre_element.Element(Nil)),
) -> lustre_element.Element(Nil) {
  editor_layout.shell_button(
    class_name: class_name,
    attributes: [
      attribute.attribute("aria-label", aria_label),
      attribute.disabled(True),
    ],
    children: children,
  )
}

fn meta_button() -> lustre_element.Element(Nil) {
  editor_layout.tab_meta_button(
    aria_label: "Edit selected tab",
    pill_label: "Edit",
    attributes: [attribute.disabled(True)],
  )
}

fn metadata_items(model: EditorModel) -> List(lustre_element.Element(Nil)) {
  [
    metadata_item("Language", language.name(model.language)),
    metadata_item("Visibility", optional_visibility_label(model.visibility)),
    metadata_item("Author", optional_label(model.owner_username)),
    metadata_item("Created", optional_timestamp_label(model.created_at)),
    metadata_item("Updated", optional_timestamp_label(model.updated_at)),
  ]
  |> collect_metadata_items([])
}

fn metadata_item(
  label: String,
  value: String,
) -> option.Option(lustre_element.Element(Nil)) {
  case string.trim(value) == "" {
    True -> option.None
    False -> option.Some(editor_layout.dialog_info_row(label, value))
  }
}

fn tab_views(model: EditorModel) -> List(lustre_element.Element(Nil)) {
  let file_tabs = file_tab_views(model.files, 0)

  case model.stdin {
    option.Some(_) ->
      list.append(file_tabs, [
        tab_button("<stdin>", False, "editor-stdin-tab"),
      ])
    option.None -> file_tabs
  }
}

fn file_tab_views(
  files: List(snippet_model.File),
  index: Int,
) -> List(lustre_element.Element(Nil)) {
  case files {
    [] -> []
    [file, ..rest] -> [
      tab_button(
        tab_label(file.name),
        index == 0,
        "editor-file-tab-" <> int.to_string(index),
      ),
      ..file_tab_views(rest, index + 1)
    ]
  }
}

fn tab_button(
  label: String,
  is_selected: Bool,
  id: String,
) -> lustre_element.Element(Nil) {
  editor_layout.tab_button(
    label: label,
    is_selected: is_selected,
    id: id,
    panel_id: "editor-source-panel",
    attributes: [attribute.disabled(True)],
  )
}

fn collect_metadata_items(
  items: List(option.Option(lustre_element.Element(Nil))),
  acc: List(lustre_element.Element(Nil)),
) -> List(lustre_element.Element(Nil)) {
  case items {
    [] -> list.reverse(acc)
    [option.Some(item), ..rest] -> collect_metadata_items(rest, [item, ..acc])
    [option.None, ..rest] -> collect_metadata_items(rest, acc)
  }
}

fn tab_label(name: String) -> String {
  name
}

fn description(view_model: ViewModel) -> String {
  case view_model {
    UnsupportedLanguage(language_slug) ->
      "Create a new " <> language_slug <> " snippet on glot.io."
    LoadError(_) -> "This code snippet is unavailable on glot.io."
    NewSnippet(model) ->
      "Write, run, save, and share "
      <> language.name(model.language)
      <> " code online with the glot.io open-source code playground."
    ExistingSnippet(model) -> snippet_summary(model)
  }
}

fn snippet_summary(model: EditorModel) -> String {
  let file_count = list.length(model.files)
  let base =
    truncate(model.title, 70)
    <> " is a "
    <> language.name(model.language)
    <> " snippet"
  let with_author = case model.owner_username {
    option.Some(owner) -> base <> " by @" <> owner
    option.None -> base
  }
  let with_count =
    with_author
    <> " with "
    <> int.to_string(file_count)
    <> " file"
    <> case file_count == 1 {
      True -> ""
      False -> "s"
    }

  with_count <> "."
}

fn snippet_page_title(title: String, language_name: String) -> String {
  let suffix = " – " <> language_name <> " snippet | glot.io"
  truncate(title, 60 - string.length(suffix)) <> suffix
}

fn truncate(value: String, max_length: Int) -> String {
  case string.length(value) > max_length {
    True -> string.slice(value, at_index: 0, length: max_length - 1) <> "…"
    False -> value
  }
}

fn og_type(view_model: ViewModel) -> String {
  case view_model {
    ExistingSnippet(_) -> "article"
    _ -> "website"
  }
}

fn canonical_path(view_model: ViewModel) -> String {
  case view_model {
    UnsupportedLanguage(language_slug) ->
      route.to_string(route.Public(route.NewSnippet(language_slug)))
    LoadError(_) -> "/snippets"
    NewSnippet(model) ->
      route.to_string(
        route.Public(route.NewSnippet(language.to_string(model.language))),
      )
    ExistingSnippet(EditorModel(slug: option.Some(slug), ..)) ->
      route.to_string(route.Public(route.Snippet(slug)))
    ExistingSnippet(_) -> "/snippets"
  }
}

fn article_meta(view_model: ViewModel) -> List(lustre_element.Element(Nil)) {
  case view_model {
    ExistingSnippet(model) -> collect_article_meta(model, [])
    _ -> []
  }
}

fn structured_data(view_model: ViewModel) -> List(lustre_element.Element(Nil)) {
  case view_model {
    ExistingSnippet(model)
      if model.visibility == option.Some(snippet_model.Public)
    -> {
      let fields = [
        #("@context", json.string("https://schema.org")),
        #("@type", json.string("SoftwareSourceCode")),
        #("name", json.string(model.title)),
        #("description", json.string(snippet_summary(model))),
        #("url", json.string(seo.site_url <> canonical_path(view_model))),
        #("programmingLanguage", json.string(language.name(model.language))),
        #("codeSampleType", json.string("full")),
      ]
      let fields = case model.owner_username {
        option.Some(owner) -> [
          #(
            "author",
            json.object([
              #("@type", json.string("Person")),
              #("name", json.string(owner)),
            ]),
          ),
          ..fields
        ]
        option.None -> fields
      }
      let fields = case model.created_at {
        option.Some(created_at) -> [
          #("dateCreated", json.string(timestamp_label(created_at))),
          ..fields
        ]
        option.None -> fields
      }
      let fields = case model.updated_at {
        option.Some(updated_at) -> [
          #("dateModified", json.string(timestamp_label(updated_at))),
          ..fields
        ]
        option.None -> fields
      }

      [seo.json_ld(json.object(fields))]
    }
    _ -> []
  }
}

fn collect_article_meta(
  model: EditorModel,
  acc: List(lustre_element.Element(Nil)),
) -> List(lustre_element.Element(Nil)) {
  let acc = case model.owner_username {
    option.Some(owner) -> [seo.meta_property("article:author", owner), ..acc]
    option.None -> acc
  }
  let acc = case model.created_at {
    option.Some(created_at) -> [
      seo.meta_property("article:published_time", timestamp_label(created_at)),
      ..acc
    ]
    option.None -> acc
  }
  let acc = case model.updated_at {
    option.Some(updated_at) -> [
      seo.meta_property("article:modified_time", timestamp_label(updated_at)),
      ..acc
    ]
    option.None -> acc
  }

  list.reverse(acc)
}

fn timestamp_label(value: timestamp.Timestamp) -> String {
  timestamp.to_rfc3339(value, calendar.utc_offset)
}

fn encode_editor_model(model: EditorModel) -> json.Json {
  json.object([
    #("slug", json.nullable(model.slug, json.string)),
    #(
      "ownerUserId",
      json.nullable(model.owner_user_id, fn(id) {
        json.string(uuid.to_string(id))
      }),
    ),
    #("ownerUsername", json.nullable(model.owner_username, json.string)),
    #("title", json.string(model.title)),
    #("language", language.encode(model.language)),
    #(
      "visibility",
      json.nullable(model.visibility, snippet_model.encode_visibility),
    ),
    #("createdAt", json.nullable(model.created_at, timestamp_helpers.encode)),
    #("updatedAt", json.nullable(model.updated_at, timestamp_helpers.encode)),
    #(
      "runInstructionsOverride",
      json.nullable(
        model.run_instructions_override,
        language.encode_run_instructions,
      ),
    ),
    #("files", json.array(model.files, snippet_model.encode_file)),
    #("stdin", json.nullable(model.stdin, json.string)),
  ])
}

fn editor_model_decoder() -> decode.Decoder(EditorModel) {
  use slug <- decode.field("slug", decode.optional(decode.string))
  use owner_user_id <- decode.field(
    "ownerUserId",
    decode.optional(uuid_helpers.decoder()),
  )
  use owner_username <- decode.field(
    "ownerUsername",
    decode.optional(decode.string),
  )
  use title <- decode.field("title", decode.string)
  use language <- decode.field("language", language.decoder())
  use visibility <- decode.field(
    "visibility",
    decode.optional(snippet_model.visibility_decoder()),
  )
  use created_at <- decode.field(
    "createdAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use updated_at <- decode.field(
    "updatedAt",
    decode.optional(timestamp_helpers.decoder()),
  )
  use run_instructions_override <- decode.field(
    "runInstructionsOverride",
    decode.optional(language.run_instructions_decoder()),
  )
  use files <- decode.field("files", decode.list(snippet_model.file_decoder()))
  use stdin <- decode.field("stdin", decode.optional(decode.string))

  decode.success(EditorModel(
    slug: slug,
    owner_user_id: owner_user_id,
    owner_username: owner_username,
    title: title,
    language: language,
    visibility: visibility,
    created_at: created_at,
    updated_at: updated_at,
    run_instructions_override: run_instructions_override,
    files: files,
    stdin: stdin,
  ))
}

fn default_editor_model(lang: language.Language) -> EditorModel {
  let default_file = snippet_model.default_file(lang)

  EditorModel(
    slug: option.None,
    owner_user_id: option.None,
    owner_username: option.None,
    title: "Hello World",
    language: lang,
    visibility: option.None,
    created_at: option.None,
    updated_at: option.None,
    run_instructions_override: option.None,
    files: [default_file],
    stdin: option.None,
  )
}

fn title_or_default(value: String) -> String {
  case string.trim(value) {
    "" -> "Untitled snippet"
    trimmed -> trimmed
  }
}

fn stdin_option(value: String) -> option.Option(String) {
  case value {
    "" -> option.None
    _ -> option.Some(value)
  }
}

fn optional_visibility_label(
  visibility: option.Option(snippet_model.Visibility),
) -> String {
  case visibility {
    option.Some(value) -> snippet_model.visibility_to_string(value)
    option.None -> ""
  }
}

fn optional_label(value: option.Option(String)) -> String {
  case value {
    option.Some(label) -> label
    option.None -> ""
  }
}

fn optional_timestamp_label(
  value: option.Option(timestamp.Timestamp),
) -> String {
  case value {
    option.Some(value) -> timestamp.to_rfc3339(value, calendar.utc_offset)
    option.None -> ""
  }
}
