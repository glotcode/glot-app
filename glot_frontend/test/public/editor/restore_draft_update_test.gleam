import gleam/option
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/restore_draft_update
import glot_frontend/public/editor/settings
import support/editor_fixture

pub fn matching_new_draft_is_offered_while_absence_clears_pending_state_test() {
  let editor = new_editor()
  let stored = stored_draft()
  let #(pending, pending_command) =
    restore_draft_update.update(
      editor,
      message.NewDraftLoaded("javascript", option.Some(stored)),
    )
  assert pending.restore_draft == model.RestoreDraftPending(stored)
  assert pending_command
    == command.OpenDialogNextFrame("editor-page-restore-draft-dialog")

  let #(absent, absent_command) =
    restore_draft_update.update(
      pending,
      message.NewDraftLoaded("javascript", option.None),
    )
  assert absent.restore_draft == model.NoRestoreDraft
  assert absent_command == command.None
}

pub fn new_draft_responses_are_correlated_to_new_editor_language_test() {
  let editor = new_editor()
  let stored = stored_draft()
  assert restore_draft_update.update(
      editor,
      message.NewDraftLoaded("python", option.Some(stored)),
    )
    == #(editor, command.None)

  let existing = existing_editor()
  assert restore_draft_update.update(
      existing,
      message.NewDraftLoaded("javascript", option.Some(stored)),
    )
    == #(existing, command.None)
}

pub fn matching_existing_draft_delegates_revision_correlation_test() {
  let editor = existing_editor()
  let stored = stored_draft()
  let updated_at = timestamp.from_unix_seconds(200)
  let #(pending, next_command) =
    restore_draft_update.update(
      editor,
      message.ExistingDraftLoaded("existing", updated_at, option.Some(stored)),
    )

  assert pending.restore_draft == model.RestoreDraftPending(stored)
  assert next_command
    == command.OpenDialogNextFrame("editor-page-restore-draft-dialog")
}

pub fn accepting_a_pending_draft_applies_it_and_closes_the_dialog_test() {
  let editor =
    model.Editor(
      ..new_editor(),
      restore_draft: model.RestoreDraftPending(stored_draft()),
    )
  let #(restored, next_command) =
    restore_draft_update.update(editor, message.RestoreDraftAccepted)

  assert restored.snippet.title == "Recovered"
  assert restored.snippet.files == [snippet_model.File("main.js", "draft")]
  assert restored.restore_draft == model.NoRestoreDraft
  assert next_command == command.CloseDialog("editor-page-restore-draft-dialog")

  let idle = new_editor()
  assert restore_draft_update.update(idle, message.RestoreDraftAccepted)
    == #(idle, command.None)
}

pub fn decline_and_close_discard_pending_state_with_distinct_effects_test() {
  let editor =
    model.Editor(
      ..new_editor(),
      restore_draft: model.RestoreDraftPending(stored_draft()),
    )
  let #(declined, decline_command) =
    restore_draft_update.update(editor, message.RestoreDraftDeclined)
  assert declined.restore_draft == model.NoRestoreDraft
  assert decline_command
    == command.Batch([
      command.CloseDialog("editor-page-restore-draft-dialog"),
      command.ClearDraft(draft_persistence.NewSnippet("javascript")),
    ])

  let #(closed, close_command) =
    restore_draft_update.update(editor, message.RestoreDraftClosed)
  assert closed.restore_draft == model.NoRestoreDraft
  assert close_command == command.Focus("editor-page-codemirror")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, settings.defaults())
}

fn existing_editor() -> model.Editor {
  let editor = new_editor()
  model.Editor(
    ..editor,
    snippet: model.Snippet(
      ..editor.snippet,
      slug: option.Some("existing"),
      updated_at: option.Some(timestamp.from_unix_seconds(200)),
    ),
  )
}

fn stored_draft() {
  editor_fixture.stored_draft(
    saved_at_ms: 200_001,
    title: "Recovered",
    files: [snippet_model.File("main.js", "draft")],
    stdin: option.None,
    run_instructions: option.None,
  )
}
