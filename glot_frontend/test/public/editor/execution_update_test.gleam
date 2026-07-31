import gleam/option
import gleam/string
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/execution_update
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import rsvp
import support/editor_fixture
import support/editor_scenario

pub fn tab_selection_does_not_mutate_entry_dialog_drafts_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let editor =
    model.Editor(
      ..editor,
      entry_drafts: model.EntryDrafts(
        add: model.AddEntryDraft(model.AddStdinEntry, "untouched-add"),
        edit: model.EditEntryDraft("untouched-edit"),
      ),
    )
  let #(selected, _) =
    execution_update.update(editor, message.TabSelected(model.FileTab(0)))

  assert selected.entry_drafts == editor.entry_drafts
  assert selected.workspace.editor_external_revision
    == editor.workspace.editor_external_revision + 1
}

pub fn tab_key_navigation_selects_and_focuses_the_destination_test() {
  let assert model.Ready(base) = editor_scenario.new_editor(language.JavaScript)
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        files: [
          snippet_model.File("main.js", "main"),
          snippet_model.File("helper.js", "helper"),
        ],
        stdin: option.Some("input"),
      ),
    )
  let #(selected, next_command) =
    execution_update.update(
      editor,
      message.TabKeyPressed(model.FileTab(0), "ArrowRight"),
    )
  assert selected.workspace.selected_tab == model.FileTab(1)
  assert next_command == command.Focus("editor-file-tab-1")

  assert execution_update.update(
      editor,
      message.TabKeyPressed(model.FileTab(0), "Enter"),
    )
    == #(editor, command.None)
}

pub fn source_change_updates_revision_content_and_persists_the_draft_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let #(changed, next_command) =
    execution_update.update(
      editor,
      message.SourceCodeChanged("updated source", 42),
    )

  assert changed.workspace.editor_revision == 42
  assert changed.snippet.files
    == [snippet_model.File("main.js", "updated source")]
  assert next_command == command.SaveDraft(draft_projection.write(changed))
}

pub fn current_run_results_and_failures_update_execution_feedback_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let #(running_operations, generation) =
    operations.begin_execution(editor.operations)
  let running = model.Editor(..editor, operations: running_operations)
  let runtime_failure = Error(run.FailedRun("Compilation failed."))
  let #(completed, completed_command) =
    execution_update.update(
      running,
      message.RunFinished(generation, response.Success(runtime_failure)),
    )
  assert operations.execution_state(completed.operations)
    == execution_operation.Completed(runtime_failure)
  assert completed_command == command.None

  let #(running_operations, generation) =
    operations.begin_execution(editor.operations)
  let running = model.Editor(..editor, operations: running_operations)
  let #(api_failed, api_command) =
    execution_update.update(
      running,
      message.RunFinished(
        generation,
        editor_fixture.api_failure("Run rejected."),
      ),
    )
  let assert execution_operation.RequestError(api_error) =
    operations.execution_state(api_failed.operations)
  assert string.contains(api_error, "Run rejected.")
  assert string.contains(api_error, "Request ID:")
  assert api_command == command.None

  let #(running_operations, generation) =
    operations.begin_execution(editor.operations)
  let running = model.Editor(..editor, operations: running_operations)
  let #(http_failed, http_command) =
    execution_update.update(
      running,
      message.RunFinished(generation, response.HttpFailure(rsvp.BadBody)),
    )
  assert operations.execution_state(http_failed.operations)
    == execution_operation.RequestError("Could not complete run.")
  assert http_command == command.None
}

pub fn stale_run_completion_is_ignored_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let #(first, stale_generation) = operations.begin_execution(editor.operations)
  let #(latest, _) = operations.begin_execution(first)
  let latest_editor = model.Editor(..editor, operations: latest)

  assert execution_update.update(
      latest_editor,
      message.RunFinished(
        stale_generation,
        editor_fixture.successful_run(stdout: "stale", stderr: "", error: ""),
      ),
    )
    == #(latest_editor, command.None)
}

pub fn version_response_is_recorded_only_for_the_current_language_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let #(versioned, version_command) =
    execution_update.update(
      editor,
      message.VersionRunFinished(
        language.JavaScript,
        editor_fixture.successful_run(stdout: "v22", stderr: "", error: ""),
      ),
    )
  assert operations.version_info(versioned.operations) == option.Some("v22")
  assert version_command == command.None

  assert execution_update.update(
      editor,
      message.VersionRunFinished(
        language.Python,
        editor_fixture.successful_run(
          stdout: "Python 3 stale",
          stderr: "",
          error: "",
        ),
      ),
    )
    == #(editor, command.None)
}

pub fn empty_and_failed_version_responses_leave_the_editor_unchanged_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  assert execution_update.update(
      editor,
      message.VersionRunFinished(
        language.JavaScript,
        response.Success(Ok(run.SuccessfulRun(1, "", "", ""))),
      ),
    )
    == #(editor, command.None)
  assert execution_update.update(
      editor,
      message.VersionRunFinished(
        language.JavaScript,
        editor_fixture.api_failure("No version."),
      ),
    )
    == #(editor, command.None)
}
