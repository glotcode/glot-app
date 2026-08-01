import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/api/http_error
import glot_frontend/api/response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/save_operation
import glot_frontend/public/editor/save_update
import glot_frontend/public/editor/settings
import support/editor_fixture

pub fn dialog_messages_reset_only_the_save_draft_test() {
  let editor =
    model.Editor(
      ..new_editor(),
      save_draft: model.SaveDraft(snippet_model.Secret),
      metadata_draft: model.MetadataDraft(
        "Uncommitted metadata",
        snippet_model.Public,
      ),
    )
  let #(cancelled, cancel_command) =
    save_update.update(
      editor,
      message.SaveCancelled,
      option.Some(editor_fixture.owner_id()),
    )
  assert cancelled.save_draft.visibility == cancelled.snippet.visibility
  assert cancelled.metadata_draft == editor.metadata_draft
  assert cancel_command == command.CloseDialog("editor-page-save-dialog")

  let #(closed, close_command) =
    save_update.update(
      editor,
      message.SaveDialogClosed,
      option.Some(editor_fixture.owner_id()),
    )
  assert closed.save_draft.visibility == closed.snippet.visibility
  assert closed.metadata_draft == editor.metadata_draft
  assert close_command == command.Focus("editor-page-codemirror")
}

pub fn visibility_selection_changes_only_the_save_draft_test() {
  let editor = new_editor()
  let #(selected, next_command) =
    save_update.update(
      editor,
      message.SaveVisibilityDraftSelected(snippet_model.Secret),
      option.Some(editor_fixture.owner_id()),
    )

  assert selected.save_draft.visibility == snippet_model.Secret
  assert selected.snippet == editor.snippet
  assert next_command == command.None
}

pub fn anonymous_confirmation_cannot_start_a_save_test() {
  let editor = new_editor()
  assert save_update.update(editor, message.SaveConfirmed, option.None)
    == #(editor, command.None)
  assert operations.save_state(editor.operations) == save_operation.SaveIdle
}

pub fn successful_create_uses_originating_request_after_logout_test() {
  let editor = new_editor()
  let #(saving_operations, generation) =
    operations.begin_save(editor.operations)
  let saving = model.Editor(..editor, operations: saving_operations)
  let created = editor_fixture.snippet("created", "source")
  let #(saved, next_command) =
    save_update.update(
      saving,
      message.SaveFinished(
        generation,
        policy.CreateSnippet(snippet_model.Unlisted),
        response.Success(created),
      ),
      option.None,
    )

  assert next_command
    == command.Batch([
      command.ClearDraft(draft_persistence.NewSnippet("javascript")),
      command.Navigate("/snippets/created"),
    ])
  assert operations.save_state(saved.operations)
    == save_operation.Saved("created")
}

pub fn successful_update_uses_originating_request_after_user_change_test() {
  let editor = existing_editor()
  let #(saving_operations, generation) =
    operations.begin_save(editor.operations)
  let saving = model.Editor(..editor, operations: saving_operations)
  let updated = editor_fixture.snippet("existing", "updated")
  let #(saved, next_command) =
    save_update.update(
      saving,
      message.SaveFinished(
        generation,
        policy.UpdateSnippet("existing", snippet_model.Unlisted),
        response.Success(updated),
      ),
      option.Some(editor_fixture.other_user_id()),
    )

  assert next_command
    == command.ClearDraft(draft_persistence.ExistingSnippet("existing"))
  assert operations.save_state(saved.operations)
    == save_operation.Saved("existing")
}

pub fn stale_save_completion_is_ignored_test() {
  let editor = new_editor()
  let #(first, stale_generation) = operations.begin_save(editor.operations)
  let #(latest, _) = operations.begin_save(first)
  let latest_editor = model.Editor(..editor, operations: latest)

  assert save_update.update(
      latest_editor,
      message.SaveFinished(
        stale_generation,
        policy.CreateSnippet(snippet_model.Unlisted),
        response.Success(editor_fixture.snippet("stale", "source")),
      ),
      option.Some(editor_fixture.owner_id()),
    )
    == #(latest_editor, command.None)
}

pub fn current_failures_update_save_feedback_without_commands_test() {
  let editor = existing_editor()
  let #(saving_operations, generation) =
    operations.begin_save(editor.operations)
  let saving = model.Editor(..editor, operations: saving_operations)
  let #(api_failed, api_command) =
    save_update.update(
      saving,
      message.SaveFinished(
        generation,
        policy.UpdateSnippet("existing", snippet_model.Unlisted),
        editor_fixture.api_failure("Update rejected."),
      ),
      option.Some(editor_fixture.owner_id()),
    )
  let assert save_operation.SaveError(api_error) =
    operations.save_state(api_failed.operations)
  assert string.contains(api_error, "Update rejected.")
  assert string.contains(api_error, "Request ID:")
  assert api_command == command.None

  let #(saving_operations, generation) =
    operations.begin_save(editor.operations)
  let saving = model.Editor(..editor, operations: saving_operations)
  let #(http_failed, http_command) =
    save_update.update(
      saving,
      message.SaveFinished(
        generation,
        policy.UpdateSnippet("existing", snippet_model.Unlisted),
        response.HttpFailure(http_error.BodyReadError),
      ),
      option.Some(editor_fixture.owner_id()),
    )
  assert operations.save_state(http_failed.operations)
    == save_operation.SaveError("Could not complete Update snippet.")
  assert http_command == command.None
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
      owner_user_id: option.Some(editor_fixture.owner_id()),
    ),
  )
}
