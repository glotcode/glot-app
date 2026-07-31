import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/snippet_info_view
import lustre/element
import support/editor_fixture

pub fn unsaved_snippet_renders_only_available_information_test() {
  let rendered = new_editor() |> render

  assert string.contains(rendered, "aria-label=\"Snippet information\"")
  assert string.contains(rendered, "Hello World")
  assert string.contains(rendered, "JavaScript")
  assert string.contains(rendered, "This snippet has not been saved yet.")
  assert !string.contains(rendered, "https://glot.io/snippets/")
}

pub fn saved_snippet_renders_complete_metadata_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        slug: option.Some("info-fixture"),
        owner_user_id: option.Some(editor_fixture.owner_id()),
        owner_username: option.Some("fixture-owner"),
        title: "Information title",
        visibility: snippet_model.Public,
        created_at: option.Some(timestamp.from_unix_seconds(100)),
        updated_at: option.Some(timestamp.from_unix_seconds(200)),
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "Information title")
  assert string.contains(rendered, "fixture-owner")
  assert string.contains(rendered, "PUBLIC")
  assert string.contains(rendered, "https://glot.io/snippets/info-fixture")
  assert string.contains(rendered, "1970-01-01T00:01:40Z")
  assert string.contains(rendered, "1970-01-01T00:03:20Z")
}

pub fn missing_saved_metadata_uses_explicit_unknown_labels_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        slug: option.Some("incomplete"),
        owner_user_id: option.None,
        owner_username: option.None,
        created_at: option.None,
        updated_at: option.None,
      ),
    )
  let rendered = render(editor)

  assert string.contains(
    rendered,
    "class=\"editor-page__dialog-copy\">Unknown</p>",
  )
}

pub fn owner_id_is_used_when_a_saved_snippet_has_no_username_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        slug: option.Some("owner-id-fallback"),
        owner_user_id: option.Some(editor_fixture.owner_id()),
        owner_username: option.None,
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "00000000-0000-4000-8000-000000000010")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn render(editor: model.Editor) -> String {
  snippet_info_view.dialog(editor) |> element.to_document_string
}
