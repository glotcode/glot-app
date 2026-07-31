import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/managed
import glot_frontend/public/editor/message
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/save_operation
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/view
import lustre/element
import support/editor_fixture
import support/editor_scenario
import youid/uuid.{type Uuid}

pub fn existing_save_failure_can_retry_without_losing_edits_test() {
  let original = editor_fixture.snippet("save-retry", "console.log('old')")
  let scenario =
    ready_existing(original, option.Some(editor_fixture.owner_id()))
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "console.log('retained')",
      1,
    ))
    |> editor_scenario.dispatch_save(message.SaveClicked)
    |> editor_scenario.respond_to_update(editor_fixture.api_failure(
      "Update rejected.",
    ))
  let failed = editor_scenario.editor(scenario)
  let assert save_operation.SaveError(error) =
    operations.save_state(failed.operations)
  assert string.contains(error, "Update rejected.")
  assert failed.snippet.files
    == [snippet_model.File("main.js", "console.log('retained')")]
  assert string.contains(
    render(scenario, editor_fixture.owner_id()),
    "SAVE FAILED",
  )

  let scenario = editor_scenario.dispatch_save(scenario, message.SaveClicked)
  let assert [editor_scenario.UpdateSnippet(request, _)] =
    editor_scenario.pending(scenario)
  let scenario =
    editor_scenario.respond_to_update(
      scenario,
      response.Success(editor_fixture.updated(original, request.data)),
    )
  let saved = editor_scenario.editor(scenario)
  assert operations.save_state(saved.operations)
    == save_operation.Saved(original.slug)
  assert observed_draft_clear(editor_scenario.observed(scenario))
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn stale_existing_save_response_cannot_overwrite_latest_success_test() {
  let original = editor_fixture.snippet("stale-save", "before")
  let scenario =
    ready_existing(original, option.Some(editor_fixture.owner_id()))
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged("first", 1))
    |> editor_scenario.dispatch_save(message.SaveClicked)
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged("second", 2))
    |> editor_scenario.dispatch_save(message.SaveClicked)
  let assert [
    editor_scenario.UpdateSnippet(_, _),
    editor_scenario.UpdateSnippet(latest, _),
  ] = editor_scenario.pending(scenario)
  let scenario =
    editor_scenario.respond_to_update_at(
      scenario,
      1,
      response.Success(editor_fixture.updated(original, latest.data)),
    )
    |> editor_scenario.respond_to_update_at(
      0,
      editor_fixture.api_failure("Stale failure."),
    )
  let editor = editor_scenario.editor(scenario)
  assert operations.save_state(editor.operations)
    == save_operation.Saved(original.slug)
  assert editor.snippet.files == [snippet_model.File("main.js", "second")]
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn anonymous_existing_save_opens_login_dialog_without_api_work_test() {
  let scenario =
    ready_existing(
      editor_fixture.snippet("anonymous-save", "source"),
      option.None,
    )
    |> editor_scenario.dispatch_save(message.SaveClicked)
  assert editor_scenario.pending(scenario) == []
  assert string.contains(
    render_anonymous(scenario),
    "You need to log in before you can save snippets.",
  )
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogOpened("editor-page-save-dialog"),
  )
}

pub fn non_owner_save_creates_a_copy_instead_of_updating_test() {
  let original = editor_fixture.snippet("someone-elses", "source")
  let current_user = editor_fixture.other_user_id()
  let scenario =
    ready_existing(original, option.Some(current_user))
    |> editor_scenario.dispatch_save(message.SaveClicked)
  assert string.contains(render(scenario, current_user), "create a new snippet")
  let scenario = editor_scenario.dispatch_save(scenario, message.SaveConfirmed)
  let assert [editor_scenario.CreateSnippet(request, _)] =
    editor_scenario.pending(scenario)
  assert request.data.files == original.data.files
  assert request.data.visibility == original.data.visibility
}

pub fn create_uses_selected_visibility_and_can_retry_after_failure_test() {
  let current_user = editor_fixture.owner_id()
  let scenario =
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.Some(current_user))
    |> editor_scenario.dispatch_save(message.SaveClicked)
    |> editor_scenario.dispatch_save(message.SaveVisibilityDraftSelected(
      snippet_model.Secret,
    ))
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  let assert [editor_scenario.CreateSnippet(first_request, _)] =
    editor_scenario.pending(scenario)
  assert first_request.data.visibility == snippet_model.Secret
  let scenario =
    editor_scenario.respond_to_create(
      scenario,
      editor_fixture.api_failure("Create rejected."),
    )
  let failed = editor_scenario.editor(scenario)
  let assert save_operation.SaveError(_) =
    operations.save_state(failed.operations)

  let scenario =
    editor_scenario.dispatch_save(scenario, message.SaveClicked)
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  let assert [editor_scenario.CreateSnippet(retry, _)] =
    editor_scenario.pending(scenario)
  let created = created_from_request("created-after-retry", retry)
  let scenario =
    editor_scenario.respond_to_create(scenario, response.Success(created))
  let saved = editor_scenario.editor(scenario)
  assert operations.save_state(saved.operations)
    == save_operation.Saved("created-after-retry")
  assert observed_navigation(
    editor_scenario.observed(scenario),
    "/snippets/created-after-retry",
  )
  assert observed_draft_clear(editor_scenario.observed(scenario))
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn cancelling_and_closing_save_dialog_restore_visibility_draft_test() {
  let current_user = editor_fixture.owner_id()
  let scenario =
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.Some(current_user))
    |> editor_scenario.dispatch_metadata(message.EditMetadataVisibilitySelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch_save(message.SaveClicked)
    |> editor_scenario.dispatch_save(message.SaveVisibilityDraftSelected(
      snippet_model.Secret,
    ))
    |> editor_scenario.dispatch_save(message.SaveCancelled)
  let cancelled = editor_scenario.editor(scenario)
  assert cancelled.save_draft.visibility == cancelled.snippet.visibility
  assert cancelled.metadata_draft.visibility == snippet_model.Public
  assert editor_scenario.pending(scenario) == []

  let scenario =
    editor_scenario.dispatch_save(scenario, message.SaveClicked)
    |> editor_scenario.dispatch_save(message.SaveVisibilityDraftSelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch_save(message.SaveDialogClosed)
  let closed = editor_scenario.editor(scenario)
  assert closed.save_draft.visibility == closed.snippet.visibility
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn stale_create_response_cannot_repeat_navigation_or_draft_clear_test() {
  let current_user = editor_fixture.owner_id()
  let scenario =
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.Some(current_user))
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged("newer", 1))
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  let assert [
    editor_scenario.CreateSnippet(_, _),
    editor_scenario.CreateSnippet(latest, _),
  ] = editor_scenario.pending(scenario)
  let latest_response = created_from_request("latest", latest)
  let stale_response = created_from_request("stale", latest)
  let scenario =
    editor_scenario.respond_to_create_at(
      scenario,
      1,
      response.Success(latest_response),
    )
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "unsaved after latest response",
      2,
    ))
    |> editor_scenario.respond_to_create_at(0, response.Success(stale_response))
  let effects = editor_scenario.observed(scenario)
  assert count_navigations(effects) == 1
  assert count_draft_clears(effects) == 1
  assert observed_navigation(effects, "/snippets/latest")
  let editor = editor_scenario.editor(scenario)
  assert editor.snippet.files
    == [snippet_model.File("main.js", "unsaved after latest response")]
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn save_after_run_becomes_the_latest_console_feedback_test() {
  let current_user = editor_fixture.owner_id()
  let scenario =
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.Some(current_user))
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
    |> editor_scenario.respond_to_run(editor_fixture.successful_run(
      stdout: "run output",
      stderr: "",
      error: "",
    ))
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  assert string.contains(render(scenario, current_user), "Saving snippet...")
  let assert [editor_scenario.CreateSnippet(request, _)] =
    editor_scenario.pending(scenario)
  let scenario =
    editor_scenario.respond_to_create(
      scenario,
      response.Success(created_from_request("saved-latest", request)),
    )
  let rendered = render(scenario, current_user)
  assert string.contains(rendered, "Saved")
  assert !string.contains(rendered, "run output")
}

pub fn saving_state_disables_save_button_and_renders_progress_test() {
  let owner = editor_fixture.owner_id()
  let scenario =
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.Some(owner))
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  let editor = editor_scenario.editor(scenario)
  assert operations.save_state(editor.operations) == save_operation.Saving
  let rendered = render(scenario, owner)
  assert string.contains(
    rendered,
    "disabled type=\"button\">Saving...</button>",
  )
  assert string.contains(rendered, "Saving snippet...")
}

pub fn saved_existing_snippet_runs_the_saved_code_and_renders_stdout_test() {
  let original = editor_fixture.snippet("save-then-run", "before")
  let owner = editor_fixture.owner_id()
  let scenario =
    ready_existing(original, option.Some(owner))
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "console.log('saved output')",
      1,
    ))
    |> editor_scenario.dispatch_save(message.SaveClicked)
  let assert [editor_scenario.UpdateSnippet(update_request, _)] =
    editor_scenario.pending(scenario)
  let scenario =
    editor_scenario.respond_to_update(
      scenario,
      response.Success(editor_fixture.updated(original, update_request.data)),
    )
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [editor_scenario.RunCode(run_request, _)] =
    editor_scenario.pending(scenario)
  assert run_request.payload.files == update_request.data.files
  let scenario =
    editor_scenario.respond_to_run(
      scenario,
      editor_fixture.successful_run(
        stdout: "saved output\n",
        stderr: "",
        error: "",
      ),
    )
  let editor = editor_scenario.editor(scenario)
  let assert execution_operation.Completed(Ok(result)) =
    operations.execution_state(editor.operations)
  assert result.stdout == "saved output\n"
  let rendered = render(scenario, owner)
  assert string.contains(rendered, "saved output")
  assert string.contains(rendered, "editor-shell__result-header--stdout")
  editor_scenario.assert_no_pending_effects(scenario)
}

fn ready_existing(
  fixture: snippet_dto.SnippetResponse,
  current_user: option.Option(Uuid),
) -> editor_scenario.Scenario {
  let #(initial, initial_command) =
    managed.init(lifecycle.ExistingEditor(fixture.slug))
  editor_scenario.start_with_command(initial, current_user, initial_command)
  |> editor_scenario.respond_to_environment("", settings.defaults())
  |> editor_scenario.deliver_next_scheduled
  |> editor_scenario.respond_to_get_snippet(response.Success(fixture))
  |> editor_scenario.respond_to_language_version(editor_fixture.successful_run(
    stdout: "v22",
    stderr: "",
    error: "",
  ))
  |> editor_scenario.respond_to_existing_draft(option.None)
}

fn created_from_request(
  slug: String,
  request: snippet_dto.CreateSnippetRequest,
) -> snippet_dto.SnippetResponse {
  editor_fixture.updated(editor_fixture.snippet(slug, ""), request.data)
}

fn render(scenario: editor_scenario.Scenario, user_id: Uuid) -> String {
  view.view(
    editor_scenario.model(scenario),
    option.Some(user_id),
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}

fn render_anonymous(scenario: editor_scenario.Scenario) -> String {
  view.view(
    editor_scenario.model(scenario),
    option.None,
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}

fn observed_draft_clear(effects: List(editor_scenario.ObservedEffect)) -> Bool {
  list.any(effects, fn(effect) {
    case effect {
      editor_scenario.DraftCleared(_) -> True
      _ -> False
    }
  })
}

fn observed_navigation(
  effects: List(editor_scenario.ObservedEffect),
  path: String,
) -> Bool {
  list.any(effects, fn(effect) { effect == editor_scenario.Navigated(path) })
}

fn count_navigations(effects: List(editor_scenario.ObservedEffect)) -> Int {
  effects
  |> list.filter(fn(effect) {
    case effect {
      editor_scenario.Navigated(_) -> True
      _ -> False
    }
  })
  |> list.length
}

fn count_draft_clears(effects: List(editor_scenario.ObservedEffect)) -> Int {
  effects
  |> list.filter(fn(effect) {
    case effect {
      editor_scenario.DraftCleared(_) -> True
      _ -> False
    }
  })
  |> list.length
}
