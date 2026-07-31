import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/managed
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/view
import glot_frontend/request_generation
import glot_frontend/ui/delayed_loading
import glot_web/page/editor as editor_ssr
import lustre/element
import rsvp
import support/editor_fixture
import support/editor_scenario

/// Lifecycle scenarios cover initialization, loading, and draft recovery.
pub fn existing_snippet_api_failure_renders_load_error_test() {
  let scenario =
    loading_existing("api-failure")
    |> editor_scenario.respond_to_get_snippet(editor_fixture.api_failure(
      "Snippet unavailable.",
    ))
  let assert model.Lifecycle(lifecycle.LoadError(message)) =
    editor_scenario.model(scenario)
  assert string.contains(message, "Snippet unavailable.")
  assert string.contains(render(scenario), "Snippet unavailable.")
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn existing_snippet_http_failure_renders_stable_load_error_test() {
  let scenario =
    loading_existing("http-failure")
    |> editor_scenario.respond_to_get_snippet(response.HttpFailure(rsvp.BadBody))
  assert editor_scenario.model(scenario)
    == model.Lifecycle(lifecycle.LoadError("Could not load snippet."))
  assert string.contains(render(scenario), "Could not load snippet.")
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn stale_snippet_and_loading_timer_messages_for_another_slug_are_ignored_test() {
  let fixture = editor_fixture.snippet("current-slug", "current")
  let scenario =
    loading_existing(fixture.slug)
    |> editor_scenario.dispatch_lifecycle(message.SnippetLoaded(
      "other-slug",
      response.Success(editor_fixture.snippet("other-slug", "stale")),
    ))
    |> editor_scenario.dispatch_lifecycle(message.SnippetLoadingDelayElapsed(
      "other-slug",
      request_generation.initial(),
    ))
  let assert model.Lifecycle(lifecycle.LoadingSnippet(slug, _, indicator)) =
    editor_scenario.model(scenario)
  assert slug == fixture.slug
  assert delayed_loading.is_visible(indicator)

  let scenario =
    scenario
    |> editor_scenario.respond_to_get_snippet(response.Success(fixture))
    |> editor_scenario.respond_to_language_version(
      editor_fixture.successful_run(stdout: "v22", stderr: "", error: ""),
    )
    |> editor_scenario.respond_to_existing_draft(option.None)
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.slug == option.Some(fixture.slug)
}

pub fn newer_existing_draft_restores_all_recoverable_fields_test() {
  let custom = language.RunInstructions(["npm run build"], "node built.js")
  let stored =
    editor_fixture.stored_draft(
      saved_at_ms: 200_001,
      title: "Recovered existing draft",
      files: [snippet_model.File("recovered.js", "recovered source")],
      stdin: option.Some("recovered input"),
      run_instructions: option.Some(custom),
    )
  let scenario =
    existing_with_draft(
      editor_fixture.snippet("draft-restore", "saved source"),
      option.Some(stored),
    )
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogOpenedNextFrame("editor-page-restore-draft-dialog"),
  )
  let assert model.Ready(pending_editor) = editor_scenario.model(scenario)
  let assert model.RestoreDraftPending(pending_draft) =
    pending_editor.restore_draft
  assert pending_draft == stored
  let scenario =
    editor_scenario.dispatch_restore_draft(
      scenario,
      message.RestoreDraftAccepted,
    )
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.title == "Recovered existing draft"
  assert editor.snippet.files
    == [snippet_model.File("recovered.js", "recovered source")]
  assert editor.snippet.stdin == option.Some("recovered input")
  assert editor.snippet.run_instructions_override == option.Some(custom)
  assert editor.restore_draft == model.NoRestoreDraft
  assert editor.workspace.editor_external_revision == 1
  assert editor.entry_drafts.add.filename == ""
  assert editor.entry_drafts.edit.filename == "recovered.js"
}

pub fn older_existing_draft_is_cleared_without_opening_restore_dialog_test() {
  let stored =
    editor_fixture.stored_draft(
      saved_at_ms: 199_999,
      title: "Old draft",
      files: [snippet_model.File("old.js", "old")],
      stdin: option.None,
      run_instructions: option.None,
    )
  let scenario =
    existing_with_draft(
      editor_fixture.snippet("old-draft", "saved"),
      option.Some(stored),
    )
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DraftCleared(draft_persistence.ExistingSnippet("old-draft")),
  )
  assert !has_restore_open(editor_scenario.observed(scenario))
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.restore_draft == model.NoRestoreDraft
}

pub fn declining_new_draft_restoration_clears_storage_and_pending_state_test() {
  let scenario = new_with_draft()
  let scenario =
    editor_scenario.dispatch_restore_draft(
      scenario,
      message.RestoreDraftDeclined,
    )
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.restore_draft == model.NoRestoreDraft
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DraftCleared(draft_persistence.NewSnippet("javascript")),
  )
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogClosed("editor-page-restore-draft-dialog"),
  )
}

pub fn closing_restore_dialog_discards_pending_choice_and_focuses_editor_test() {
  let scenario =
    new_with_draft()
    |> editor_scenario.dispatch_restore_draft(message.RestoreDraftClosed)
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.restore_draft == model.NoRestoreDraft
  assert !has_draft_clear(editor_scenario.observed(scenario))
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.ElementFocused("editor-page-codemirror"),
  )
}

pub fn filtered_or_absent_new_draft_does_not_open_restore_dialog_test() {
  let scenario =
    ready_new_with_version(
      response.Success(Ok(run.SuccessfulRun(1, "v22", "", ""))),
    )
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.restore_draft == model.NoRestoreDraft
  assert !has_restore_open(editor_scenario.observed(scenario))
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn empty_and_failed_language_version_fixtures_leave_editor_usable_test() {
  let empty =
    ready_new_with_version(editor_fixture.successful_run(
      stdout: "",
      stderr: "",
      error: "",
    ))
  let assert model.Ready(empty_editor) = editor_scenario.model(empty)
  assert operations.version_info(empty_editor.operations) == option.None

  let failed = ready_new_with_version(editor_fixture.api_failure("No version."))
  let assert model.Ready(failed_editor) = editor_scenario.model(failed)
  assert operations.version_info(failed_editor.operations) == option.None
  assert string.contains(render(failed), "editor-page")
}

pub fn stale_language_version_from_previous_language_is_ignored_test() {
  let base = editor_scenario.new_editor(language.JavaScript)
  let scenario =
    editor_scenario.start(base, option.None)
    |> editor_scenario.dispatch_execution(message.VersionRunFinished(
      language.Python,
      editor_fixture.successful_run(
        stdout: "Python 3 stale",
        stderr: "",
        error: "",
      ),
    ))
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert operations.version_info(editor.operations) == option.None
}

pub fn unsupported_language_and_ssr_load_error_render_user_visible_states_test() {
  let #(unsupported_model, unsupported_command) =
    managed.init(lifecycle.NewEditor("not-a-language"))
  let unsupported =
    editor_scenario.start_with_command(
      unsupported_model,
      option.None,
      unsupported_command,
    )
    |> editor_scenario.respond_to_environment("", settings.defaults())
  assert string.contains(
    render(unsupported),
    "Unsupported language: not-a-language",
  )

  let raw_ssr =
    editor_ssr.LoadError("SSR could not load the editor.")
    |> editor_ssr.encode
    |> json.to_string
  let #(error_model, error_command) =
    managed.init(lifecycle.ExistingEditor("ssr-error"))
  let error_scenario =
    editor_scenario.start_with_command(error_model, option.None, error_command)
    |> editor_scenario.respond_to_environment(raw_ssr, settings.defaults())
  assert error_scenario
    |> render
    |> string.contains("SSR could not load the editor.")
}

pub fn invalid_ssr_falls_back_to_environment_settings_and_storage_fixtures_test() {
  let #(initial, command) = managed.init(lifecycle.NewEditor("javascript"))
  let scenario =
    editor_scenario.start_with_command(initial, option.None, command)
    |> editor_scenario.respond_to_environment(
      "{invalid ssr",
      settings.EditorSettings(settings.VimBindings),
    )
    |> editor_scenario.respond_to_language_version(
      editor_fixture.successful_run(stdout: "v22", stderr: "", error: ""),
    )
    |> editor_scenario.respond_to_new_draft(option.None)
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.language == language.JavaScript
  assert editor.editor_settings.keyboard_bindings == settings.VimBindings
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn valid_existing_ssr_uses_the_shared_existing_editor_transition_test() {
  let fixture = editor_fixture.snippet("ssr-existing", "server source")
  let raw_ssr =
    fixture
    |> editor_ssr.from_snippet
    |> editor_ssr.encode
    |> json.to_string
  let #(initial, command) = managed.init(lifecycle.ExistingEditor(fixture.slug))
  let scenario =
    editor_scenario.start_with_command(initial, option.None, command)
    |> editor_scenario.respond_to_environment(
      raw_ssr,
      settings.EditorSettings(settings.VimBindings),
    )
    |> editor_scenario.respond_to_language_version(
      editor_fixture.successful_run(stdout: "v22", stderr: "", error: ""),
    )
    |> editor_scenario.respond_to_existing_draft(option.None)
  let editor = editor_scenario.editor(scenario)

  assert editor.snippet.slug == option.Some(fixture.slug)
  assert editor.snippet.files == fixture.data.files
  assert editor.editor_settings.keyboard_bindings == settings.VimBindings
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn incomplete_existing_ssr_becomes_a_stable_load_error_test() {
  let fixture = editor_fixture.snippet("incomplete-ssr", "server source")
  let assert editor_ssr.ExistingSnippet(ssr_model) =
    editor_ssr.from_snippet(fixture)
  let raw_ssr =
    editor_ssr.ExistingSnippet(
      editor_ssr.EditorModel(..ssr_model, updated_at: option.None),
    )
    |> editor_ssr.encode
    |> json.to_string
  let #(initial, command) = managed.init(lifecycle.ExistingEditor(fixture.slug))
  let scenario =
    editor_scenario.start_with_command(initial, option.None, command)
    |> editor_scenario.respond_to_environment(raw_ssr, settings.defaults())

  assert editor_scenario.model(scenario)
    == model.Lifecycle(lifecycle.LoadError("Could not load snippet."))
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn stale_environment_fixture_for_another_route_is_ignored_test() {
  let target = lifecycle.NewEditor("javascript")
  let #(initial, command) = managed.init(target)
  let scenario =
    editor_scenario.start_with_command(initial, option.None, command)
    |> editor_scenario.dispatch_lifecycle(message.EnvironmentLoaded(
      lifecycle.ExistingEditor("other"),
      "",
      settings.defaults(),
    ))
  assert editor_scenario.model(scenario)
    == model.Lifecycle(lifecycle.Initializing(target))
  let scenario =
    editor_scenario.respond_to_environment(scenario, "", settings.defaults())
    |> editor_scenario.respond_to_language_version(
      editor_fixture.successful_run(stdout: "v22", stderr: "", error: ""),
    )
    |> editor_scenario.respond_to_new_draft(option.None)
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.language == language.JavaScript
}

pub fn editor_workflow_messages_are_ignored_before_the_editor_is_ready_test() {
  let target = lifecycle.NewEditor("javascript")
  let #(initial, _) = managed.init(target)
  let scenario =
    editor_scenario.start(initial, option.None)
    |> editor_scenario.dispatch_execution(message.RunSubmitted)

  assert editor_scenario.model(scenario)
    == model.Lifecycle(lifecycle.Initializing(target))
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn stale_lifecycle_messages_are_ignored_after_the_editor_is_ready_test() {
  let scenario =
    ready_new_with_version(editor_fixture.successful_run(
      stdout: "v22",
      stderr: "",
      error: "",
    ))
  let before = editor_scenario.editor(scenario)
  let scenario =
    editor_scenario.dispatch_lifecycle(
      scenario,
      message.EnvironmentLoaded(
        lifecycle.NewEditor("javascript"),
        "",
        settings.defaults(),
      ),
    )

  assert editor_scenario.editor(scenario) == before
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn ssr_unsupported_language_fixture_controls_initial_state_test() {
  let raw_ssr =
    editor_ssr.UnsupportedLanguage("server-language")
    |> editor_ssr.encode
    |> json.to_string
  let #(initial, command) = managed.init(lifecycle.NewEditor("javascript"))
  let scenario =
    editor_scenario.start_with_command(initial, option.None, command)
    |> editor_scenario.respond_to_environment(raw_ssr, settings.defaults())
  assert editor_scenario.model(scenario)
    == model.Lifecycle(lifecycle.UnsupportedLanguage("server-language"))
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn accepting_new_draft_restores_content_and_closes_dialog_test() {
  let scenario =
    new_with_draft()
    |> editor_scenario.dispatch_restore_draft(message.RestoreDraftAccepted)
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.title == "New draft"
  assert editor.snippet.files == [snippet_model.File("main.js", "draft")]
  assert editor.restore_draft == model.NoRestoreDraft
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogClosed("editor-page-restore-draft-dialog"),
  )
}

fn loading_existing(slug: String) -> editor_scenario.Scenario {
  let #(initial, command) = managed.init(lifecycle.ExistingEditor(slug))
  editor_scenario.start_with_command(initial, option.None, command)
  |> editor_scenario.respond_to_environment("", settings.defaults())
  |> editor_scenario.deliver_next_scheduled
}

fn existing_with_draft(
  fixture: snippet_dto.SnippetResponse,
  stored: option.Option(draft.StoredEditorDraft),
) -> editor_scenario.Scenario {
  loading_existing(fixture.slug)
  |> editor_scenario.respond_to_get_snippet(response.Success(fixture))
  |> editor_scenario.respond_to_language_version(editor_fixture.successful_run(
    stdout: "v22",
    stderr: "",
    error: "",
  ))
  |> editor_scenario.respond_to_existing_draft(stored)
}

fn new_with_draft() -> editor_scenario.Scenario {
  let stored =
    editor_fixture.stored_draft(
      saved_at_ms: 300_000,
      title: "New draft",
      files: [snippet_model.File("main.js", "draft")],
      stdin: option.None,
      run_instructions: option.None,
    )
  let #(initial, command) = managed.init(lifecycle.NewEditor("javascript"))
  editor_scenario.start_with_command(initial, option.None, command)
  |> editor_scenario.respond_to_environment("", settings.defaults())
  |> editor_scenario.respond_to_language_version(editor_fixture.successful_run(
    stdout: "v22",
    stderr: "",
    error: "",
  ))
  |> editor_scenario.respond_to_new_draft(option.Some(stored))
}

fn ready_new_with_version(
  version_fixture: response.Response(run.RunResult),
) -> editor_scenario.Scenario {
  let #(initial, command) = managed.init(lifecycle.NewEditor("javascript"))
  editor_scenario.start_with_command(initial, option.None, command)
  |> editor_scenario.respond_to_environment("", settings.defaults())
  |> editor_scenario.respond_to_language_version(version_fixture)
  |> editor_scenario.respond_to_new_draft(option.None)
}

fn render(scenario: editor_scenario.Scenario) -> String {
  view.view(
    editor_scenario.model(scenario),
    option.None,
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}

fn has_restore_open(effects: List(editor_scenario.ObservedEffect)) -> Bool {
  list.contains(
    effects,
    editor_scenario.DialogOpenedNextFrame("editor-page-restore-draft-dialog"),
  )
}

fn has_draft_clear(effects: List(editor_scenario.ObservedEffect)) -> Bool {
  list.any(effects, fn(effect) {
    case effect {
      editor_scenario.DraftCleared(_) -> True
      _ -> False
    }
  })
}
