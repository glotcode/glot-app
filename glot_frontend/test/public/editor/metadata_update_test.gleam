import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/message
import glot_frontend/public/editor/metadata_draft
import glot_frontend/public/editor/metadata_update
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings

pub fn opening_synchronizes_the_draft_from_authoritative_metadata_test() {
  let base = ready.new(language.JavaScript, settings.defaults())
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        title: "Authoritative title",
        visibility: snippet_model.Public,
      ),
      metadata_draft: model.MetadataDraft("Stale title", snippet_model.Secret),
    )
  let #(opened, next_command) =
    metadata_update.update(editor, message.EditMetadataClicked)

  assert opened.metadata_draft == metadata_draft.from_editor(editor)
  assert next_command == command.OpenDialog("editor-page-edit-metadata-dialog")
}

pub fn draft_messages_update_only_the_selected_metadata_field_test() {
  let editor = ready.new(language.JavaScript, settings.defaults())
  let #(title_changed, title_command) =
    metadata_update.update(editor, message.TitleDraftChanged("Draft title"))
  assert title_changed.metadata_draft.title == "Draft title"
  assert title_changed.metadata_draft.visibility
    == editor.metadata_draft.visibility
  assert title_command == command.None

  let #(visibility_changed, visibility_command) =
    metadata_update.update(
      title_changed,
      message.EditMetadataVisibilitySelected(snippet_model.Secret),
    )
  assert visibility_changed.metadata_draft.title == "Draft title"
  assert visibility_changed.metadata_draft.visibility == snippet_model.Secret
  assert visibility_command == command.None
}

pub fn submission_commits_metadata_and_persists_the_editor_draft_test() {
  let base = ready.new(language.JavaScript, settings.defaults())
  let editor =
    model.Editor(
      ..base,
      metadata_draft: model.MetadataDraft(
        "Submitted title",
        snippet_model.Public,
      ),
    )
  let #(submitted, next_command) =
    metadata_update.update(editor, message.EditMetadataSubmitted)

  assert submitted.snippet.title == "Submitted title"
  assert submitted.snippet.visibility == snippet_model.Public
  assert next_command
    == command.Batch([
      command.CloseDialog("editor-page-edit-metadata-dialog"),
      command.SaveDraft(draft_projection.write(submitted)),
    ])
}

pub fn cancel_and_close_resynchronize_with_distinct_browser_effects_test() {
  let base = ready.new(language.JavaScript, settings.defaults())
  let stale =
    model.Editor(
      ..base,
      metadata_draft: model.MetadataDraft("Stale title", snippet_model.Secret),
    )
  let #(cancelled, cancel_command) =
    metadata_update.update(stale, message.EditMetadataCancelled)
  assert cancelled.metadata_draft == metadata_draft.from_editor(stale)
  assert cancel_command
    == command.CloseDialog("editor-page-edit-metadata-dialog")

  let #(closed, close_command) =
    metadata_update.update(stale, message.EditMetadataDialogClosed)
  assert closed.metadata_draft == metadata_draft.from_editor(stale)
  assert close_command == command.Focus("editor-page-codemirror")
}
