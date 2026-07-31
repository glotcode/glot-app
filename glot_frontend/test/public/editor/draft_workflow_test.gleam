import gleam/option
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/draft_workflow
import glot_frontend/public/editor/existing_editor_transition
import glot_frontend/public/editor/model
import glot_frontend/public/editor/settings
import support/editor_fixture

pub fn loaded_existing_drafts_are_correlated_to_the_current_revision_test() {
  let editor = existing_editor()
  let stored = stored_draft()

  assert draft_workflow.apply_loaded_draft(
      editor,
      "other-slug",
      editor_fixture.snippet("draft-target", "saved").updated_at,
      option.Some(stored),
    )
    == #(editor, command.None)
  assert draft_workflow.apply_loaded_draft(
      editor,
      "draft-target",
      timestamp.from_unix_seconds(201),
      option.Some(stored),
    )
    == #(editor, command.None)
}

pub fn newer_existing_draft_is_offered_and_older_draft_is_cleared_test() {
  let editor = existing_editor()
  let updated_at = timestamp.from_unix_seconds(200)
  let stored = stored_draft()
  let #(pending, pending_command) =
    draft_workflow.apply_loaded_draft(
      editor,
      "draft-target",
      updated_at,
      option.Some(stored),
    )
  assert pending.restore_draft == model.RestoreDraftPending(stored)
  assert pending_command
    == command.OpenDialogNextFrame("editor-page-restore-draft-dialog")

  let old = draft.StoredEditorDraft(..stored, saved_at_ms: 200_000)
  assert draft_workflow.apply_loaded_draft(
      editor,
      "draft-target",
      updated_at,
      option.Some(old),
    )
    == #(
      editor,
      command.ClearDraft(draft_persistence.ExistingSnippet("draft-target")),
    )
}

pub fn applying_a_draft_rebuilds_all_dependent_editor_state_test() {
  let base = existing_editor()
  let editor =
    model.Editor(
      ..base,
      metadata_draft: model.MetadataDraft("Stale title", snippet_model.Secret),
    )
  let custom = language.RunInstructions(["npm build"], "node dist.js")
  let applied =
    draft_workflow.apply_editor_draft(
      editor,
      draft.EditorDraft(
        title: "Recovered",
        language: language.JavaScript,
        files: [
          snippet_model.File("app.js", "source"),
          snippet_model.File("helper.js", "helper"),
        ],
        stdin: option.Some("input"),
        run_instructions_override: option.Some(custom),
      ),
    )

  assert applied.snippet.title == "Recovered"
  assert applied.snippet.stdin == option.Some("input")
  assert applied.workspace.selected_tab == model.FileTab(0)
  assert applied.workspace.editor_external_revision
    == editor.workspace.editor_external_revision + 1
  assert applied.entry_drafts.add.filename == ""
  assert applied.entry_drafts.edit.filename == "app.js"
  assert applied.metadata_draft.title == "Recovered"
  assert applied.metadata_draft.visibility == base.snippet.visibility
  assert applied.settings_draft.run_instructions_mode
    == model.CustomRunInstructions
  assert applied.settings_draft.run_instructions.run_command == "node dist.js"
  assert applied.restore_draft == model.NoRestoreDraft
}

fn existing_editor() -> model.Editor {
  let fixture = editor_fixture.snippet("draft-target", "saved")
  let #(ready, _) =
    existing_editor_transition.from_response(fixture, settings.defaults())
  let assert model.Ready(editor) = ready
  editor
}

fn stored_draft() -> draft.StoredEditorDraft {
  editor_fixture.stored_draft(
    saved_at_ms: 200_001,
    title: "Recovered",
    files: [snippet_model.File("main.js", "draft")],
    stdin: option.None,
    run_instructions: option.None,
  )
}
