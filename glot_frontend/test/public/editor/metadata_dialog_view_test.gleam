import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/metadata_dialog_view
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import lustre/element

pub fn new_snippet_renders_title_draft_without_visibility_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      metadata_draft: model.MetadataDraft(
        "Unsaved title change",
        snippet_model.Secret,
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "aria-label=\"Edit snippet metadata\"")
  assert string.contains(rendered, "value=\"Unsaved title change\"")
  assert !string.contains(rendered, "aria-label=\"Visibility\"")
  assert string.contains(rendered, "type=\"submit\">Apply</button>")
}

pub fn existing_snippet_renders_the_visibility_draft_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(..base.snippet, slug: option.Some("existing")),
      metadata_draft: model.MetadataDraft(
        "Existing title",
        snippet_model.Secret,
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "aria-label=\"Visibility\"")
  assert string.contains(
    rendered,
    "editor-page__settings-option--selected\" type=\"button\"><span class=\"editor-page__settings-option-title\">Secret",
  )
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
}

fn render(editor: model.Editor) -> String {
  metadata_dialog_view.view(editor) |> element.to_document_string
}
