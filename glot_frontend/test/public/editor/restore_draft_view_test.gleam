import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/restore_draft_view
import glot_frontend/public/editor/settings
import lustre/element
import support/editor_fixture

pub fn absent_restore_draft_renders_an_empty_dialog_test() {
  let rendered = new_editor() |> render

  assert string.contains(rendered, "aria-label=\"Restore draft\"")
  assert !string.contains(rendered, "editor-page__dialog-form")
  assert !string.contains(rendered, ">Yes</button>")
}

pub fn new_snippet_restore_prompt_explains_the_local_draft_test() {
  let rendered = new_editor() |> with_pending_draft |> render

  assert string.contains(
    rendered,
    "A local draft saved 1 minute ago was found for this new snippet.",
  )
  assert string.contains(rendered, ">No</button>")
  assert string.contains(rendered, ">Yes</button>")
}

pub fn existing_snippet_restore_prompt_explains_newer_unsaved_changes_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(..base.snippet, slug: option.Some("existing")),
    )
    |> with_pending_draft
  let rendered = render(editor)

  assert string.contains(
    rendered,
    "A newer local draft saved 1 minute ago was found for this snippet.",
  )
  assert string.contains(rendered, "restore your unsaved local changes?")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn with_pending_draft(editor: model.Editor) -> model.Editor {
  let stored =
    editor_fixture.stored_draft(
      saved_at_ms: 240_000,
      title: "Recovered",
      files: editor.snippet.files,
      stdin: option.None,
      run_instructions: option.None,
    )
  model.Editor(..editor, restore_draft: model.RestoreDraftPending(stored))
}

fn render(editor: model.Editor) -> String {
  restore_draft_view.view(editor, timestamp.from_unix_seconds(300))
  |> element.to_document_string
}
