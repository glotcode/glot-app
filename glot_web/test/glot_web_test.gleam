import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import gleeunit
import glot_core/auth/user_dto
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_web/page/carbon_ad
import glot_web/page/editor
import glot_web/page/embedded_json
import glot_web/page/seo
import glot_web/page/server
import glot_web/page/snippets
import lustre/element
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn seo_login_metadata_is_not_indexable_test() {
  assert seo.robots(seo.login()) == "noindex, nofollow"
  assert seo.canonical_url(seo.login()) == "https://glot.io/login"
}

pub fn non_runnable_public_snippet_is_not_indexable_test() {
  let snippet =
    editor.ExistingSnippet(editor.EditorModel(
      slug: option.Some("non-runnable"),
      owner_user_id: option.None,
      owner_username: option.None,
      title: "Non-runnable snippet",
      language: language.JavaScript,
      visibility: option.Some(snippet_model.Public),
      created_at: option.None,
      updated_at: option.None,
      is_runnable: option.Some(False),
      run_instructions_override: option.None,
      files: [snippet_model.File("main.js", "")],
      stdin: option.None,
    ))

  assert seo.robots(editor.metadata(snippet)) == "noindex, nofollow"
}

pub fn structured_data_escapes_script_closing_tags_test() {
  let rendered =
    seo.json_ld(json.object([#("name", json.string("</script><script>"))]))
    |> element.to_document_string

  assert !string.contains(rendered, "</script><script>")
  assert string.contains(rendered, "\\u003c/script\\u003e")
}

pub fn embedded_json_escapes_html_significant_content_test() {
  let rendered =
    embedded_json.script(
      id: "json-fixture",
      data: json.object([
        #("source", json.string("</script><script>alert('xss')</script>&")),
      ]),
    )
    |> element.to_document_string

  assert string.contains(rendered, "id=\"json-fixture\"")
  assert string.contains(rendered, "type=\"application/json\"")
  assert !string.contains(rendered, "</script><script>")
  assert string.contains(
    rendered,
    "\\u003c/script\\u003e\\u003cscript\\u003ealert('xss')\\u003c/script\\u003e\\u0026",
  )
}

pub fn plaintext_cannot_be_used_for_a_new_editor_test() {
  assert editor.new("plaintext") == editor.UnsupportedLanguage("plaintext")
}

pub fn editor_document_embeds_large_ssr_payload_outside_app_attributes_test() {
  let large_source =
    string.repeat("x", times: 100_000)
    <> "</script><script>alert('xss')</script>&"
  let view_model =
    editor.NewSnippet(editor.EditorModel(
      slug: option.None,
      owner_user_id: option.None,
      owner_username: option.None,
      title: "Large fixture",
      language: language.JavaScript,
      visibility: option.None,
      created_at: option.None,
      updated_at: option.None,
      is_runnable: option.None,
      run_instructions_override: option.None,
      files: [snippet_model.File("main.js", large_source)],
      stdin: option.None,
    ))
  let rendered =
    server.editor_document(render_config(), view_model, "https://glot.io/image")

  assert string.contains(rendered, "<div id=\"app\"")
  assert !string.contains(rendered, "data-ssr=")
  assert string.contains(rendered, "id=\"glot-ssr-data\"")
  assert string.contains(rendered, "type=\"application/json\"")
  assert string.contains(rendered, string.repeat("x", times: 100_000))
  assert !string.contains(rendered, "</script><script>")
  assert string.contains(rendered, "\\u003c/script\\u003e")

  // The document lives in the textarea's content, never in an attribute, so a
  // 100,000 character snippet cannot bloat the opening tag.
  let assert [_, editor_element] =
    string.split(rendered, "<textarea aria-label=\"Code editor\"")
  let assert Ok(editor_opening_tag) =
    editor_element |> string.split(">") |> list.first
  assert !string.contains(editor_opening_tag, " value=")

  let opening = "<script id=\"glot-ssr-data\" type=\"application/json\">"
  let assert [_, data_and_document_end] = string.split(rendered, opening)
  let assert [raw_data, _] = string.split(data_and_document_end, "</script>")
  assert json.parse(raw_data, editor.decoder()) == Ok(view_model)
}

pub fn carbon_ad_renders_as_sandboxed_iframe_test() {
  let rendered =
    carbon_ad.view(container_class: "sponsor", load_ad: True)
    |> element.to_document_string

  assert string.contains(rendered, "src=\"/ads/carbon\"")
  assert string.contains(
    rendered,
    "sandbox=\"allow-scripts allow-popups allow-popups-to-escape-sandbox\"",
  )
  assert !string.contains(rendered, "allow-same-origin")
  assert !string.contains(rendered, "cdn.carbonads.com")
}

pub fn snippets_loading_state_hides_table_test() {
  let rendered =
    snippets.ViewModel(
      page: loadable.Loading,
      username: option.None,
      language: option.None,
      now: timestamp.from_unix_seconds_and_nanoseconds(0, 0),
    )
    |> snippets.view(False)
    |> element.to_document_string

  assert !string.contains(rendered, "snippets-table")
  assert !string.contains(rendered, "snippets-page__empty")
}

pub fn snippets_empty_loaded_state_uses_placeholder_test() {
  let rendered =
    snippets.ViewModel(
      page: loadable.Loaded(snippets.empty_page()),
      username: option.None,
      language: option.None,
      now: timestamp.from_unix_seconds_and_nanoseconds(0, 0),
    )
    |> snippets.view(False)
    |> element.to_document_string

  assert string.contains(rendered, "snippets-page__empty")
  assert string.contains(rendered, "No public snippets found.")
  assert !string.contains(rendered, "snippets-table")
}

pub fn populated_snippets_use_native_table_semantics_and_specific_link_names_test() {
  let assert Ok(user_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000001")
  let now = timestamp.from_unix_seconds(200)
  let snippet =
    snippet_dto.SnippetResponse(
      slug: "fixture",
      user: user_dto.UserResponse(id: user_id, username: "fixture-owner"),
      data: snippet_dto.SnippetData(
        title: "Fixture",
        language: language.JavaScript,
        visibility: snippet_model.Public,
        stdin: "",
        run_instructions: option.None,
        files: [snippet_model.File("main.js", "")],
      ),
      created_at: timestamp.from_unix_seconds(100),
      updated_at: now,
      is_runnable: option.None,
    )
  let rendered =
    snippets.ViewModel(
      page: loadable.Loaded(pagination_model.InitialCursorPage(
        items: [snippet],
        next_cursor: option.None,
      )),
      username: option.None,
      language: option.Some(language.JavaScript),
      now:,
    )
    |> snippets.view(False)
    |> element.to_document_string

  assert string.contains(rendered, "<table class=\"snippets-table\"")
  assert string.contains(rendered, "<caption class=\"visually-hidden\"")
  assert string.contains(rendered, "<thead>")
  assert string.contains(rendered, "<tbody class=\"snippets-table__body\"")
  assert string.contains(rendered, "scope=\"col\"")
  assert string.contains(
    rendered,
    "aria-label=\"Filter by user fixture-owner\"",
  )
  assert string.contains(
    rendered,
    "aria-label=\"Filter by language JavaScript\"",
  )
  assert string.contains(rendered, "/snippets?language=javascript")
  assert string.contains(rendered, "Filtered by JavaScript")
  assert string.contains(
    rendered,
    "/snippets?username=fixture-owner&amp;language=javascript",
  )
  assert !string.contains(rendered, "aria-label=\"Filter by user\"")
}

fn render_config() -> server.RenderConfig {
  server.RenderConfig(
    theme: option.None,
    stylesheet_href: "/styles.css",
    additional_stylesheet_hrefs: [],
    frontend_src: "/frontend.js",
    frontend_preloads: [],
  )
}
