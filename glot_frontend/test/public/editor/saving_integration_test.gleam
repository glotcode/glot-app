import gleam/list
import gleam/option
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/managed
import glot_frontend/public/editor/message
import support/editor_fixture
import support/editor_scenario
import youid/uuid.{type Uuid}

pub fn existing_save_failure_can_retry_without_losing_edits_test() {
  let original = editor_fixture.snippet("save-retry", "console.log('old')")
  let scenario =
    ready_existing(original, option.Some(editor_fixture.owner_id()))
    |> editor_scenario.type_source("console.log('retained')")
    |> editor_scenario.dispatch_save(message.SaveClicked)
    |> editor_scenario.respond_to_update(editor_fixture.api_failure(
      "Update rejected.",
    ))
  let failed = editor_scenario.editor(scenario)
  assert failed.snippet.files
    == [snippet_model.File("main.js", "console.log('retained')")]

  let scenario = editor_scenario.dispatch_save(scenario, message.SaveClicked)
  let assert [editor_scenario.UpdateSnippet(request, _)] =
    editor_scenario.pending(scenario)
  let scenario =
    editor_scenario.respond_to_update(
      scenario,
      response.Success(editor_fixture.updated(original, request.data)),
    )
  assert editor_scenario.observed_draft_clear(scenario)
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn stale_existing_save_response_cannot_overwrite_latest_success_test() {
  let original = editor_fixture.snippet("stale-save", "before")
  let scenario =
    ready_existing(original, option.Some(editor_fixture.owner_id()))
    |> editor_scenario.type_source("first")
    |> editor_scenario.dispatch_save(message.SaveClicked)
    |> editor_scenario.type_source("second")
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
  let scenario = editor_scenario.dispatch_save(scenario, message.SaveConfirmed)
  let assert [editor_scenario.CreateSnippet(_, _)] =
    editor_scenario.pending(scenario)
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

  let scenario =
    editor_scenario.dispatch_save(scenario, message.SaveClicked)
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  let assert [editor_scenario.CreateSnippet(retry, _)] =
    editor_scenario.pending(scenario)
  let created = created_from_request("created-after-retry", retry)
  let scenario =
    editor_scenario.respond_to_create(scenario, response.Success(created))
  assert editor_scenario.observed_navigation(
    scenario,
    "/snippets/created-after-retry",
  )
  assert editor_scenario.observed_draft_clear(scenario)
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn stale_create_response_cannot_repeat_navigation_or_draft_clear_test() {
  let current_user = editor_fixture.owner_id()
  let scenario =
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.Some(current_user))
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
    |> editor_scenario.type_source("newer")
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
    |> editor_scenario.type_source("unsaved after latest response")
    |> editor_scenario.respond_to_create_at(0, response.Success(stale_response))
  assert editor_scenario.count_navigations(scenario) == 1
  assert editor_scenario.count_draft_clears(scenario) == 1
  assert editor_scenario.observed_navigation(scenario, "/snippets/latest")
  let editor = editor_scenario.editor(scenario)
  assert editor.snippet.files
    == [snippet_model.File("main.js", "unsaved after latest response")]
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn saved_existing_snippet_runs_the_saved_code_test() {
  let original = editor_fixture.snippet("save-then-run", "before")
  let owner = editor_fixture.owner_id()
  let scenario =
    ready_existing(original, option.Some(owner))
    |> editor_scenario.type_source("console.log('saved output')")
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
    |> editor_scenario.deliver_next_scheduled
  editor_scenario.assert_no_pending_effects(scenario)
}

fn ready_existing(
  fixture: snippet_dto.SnippetResponse,
  current_user: option.Option(Uuid),
) -> editor_scenario.Scenario {
  let #(initial, initial_command) =
    managed.init(lifecycle.ExistingEditor(fixture.slug))
  editor_scenario.start_with_command(initial, current_user, initial_command)
  |> editor_scenario.respond_to_environment("", environment.defaults())
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
