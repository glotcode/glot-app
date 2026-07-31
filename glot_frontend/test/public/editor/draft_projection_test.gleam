import gleam/option
import glot_core/language
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings

pub fn new_editor_drafts_target_the_language_storage_scope_test() {
  let editor = ready.new(language.JavaScript, settings.defaults())

  assert draft_projection.target(editor)
    == draft_persistence.NewSnippet("javascript")
}

pub fn existing_editor_drafts_target_the_snippet_storage_scope_test() {
  let editor = ready.new(language.JavaScript, settings.defaults())
  let editor =
    model.Editor(
      ..editor,
      snippet: model.Snippet(
        ..editor.snippet,
        slug: option.Some("existing-snippet"),
      ),
    )

  assert draft_projection.target(editor)
    == draft_persistence.ExistingSnippet("existing-snippet")
}

pub fn draft_writes_exclude_unrelated_editor_ui_state_test() {
  let editor = ready.new(language.JavaScript, settings.defaults())
  let changed_ui_state =
    model.Editor(
      ..editor,
      workspace: model.Workspace(
        ..editor.workspace,
        editor_revision: 42,
        editor_external_revision: 7,
      ),
      metadata_draft: model.MetadataDraft(
        title: "Uncommitted title",
        visibility: editor.metadata_draft.visibility,
      ),
    )

  assert draft_projection.write(changed_ui_state)
    == draft_projection.write(editor)
}
