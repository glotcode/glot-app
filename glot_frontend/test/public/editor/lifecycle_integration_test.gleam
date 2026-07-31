import gleam/json
import gleam/list
import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/managed
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/settings
import glot_web/page/editor as editor_ssr
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
  assert string.contains(
    editor_scenario.render(scenario),
    "Snippet unavailable.",
  )
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn newer_existing_draft_opens_and_can_be_restored_test() {
  let stored =
    editor_fixture.stored_draft(
      saved_at_ms: 200_001,
      title: "Recovered existing draft",
      files: [snippet_model.File("recovered.js", "recovered source")],
      stdin: option.Some("recovered input"),
      run_instructions: option.None,
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
  let scenario =
    editor_scenario.dispatch_restore_draft(
      scenario,
      message.RestoreDraftAccepted,
    )
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.title == "Recovered existing draft"
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogClosed("editor-page-restore-draft-dialog"),
  )
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
}

pub fn declining_new_draft_restoration_clears_storage_and_pending_state_test() {
  let scenario = new_with_draft()
  let scenario =
    editor_scenario.dispatch_restore_draft(
      scenario,
      message.RestoreDraftDeclined,
    )
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DraftCleared(draft_persistence.NewSnippet("javascript")),
  )
  assert list.contains(
    editor_scenario.observed(scenario),
    editor_scenario.DialogClosed("editor-page-restore-draft-dialog"),
  )
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
    editor_scenario.render(unsupported),
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
    |> editor_scenario.render
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
  assert editor.editor_settings.keyboard_bindings == settings.VimBindings
  editor_scenario.assert_no_pending_effects(scenario)
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
    editor_scenario.new_editor(language.JavaScript)
    |> editor_scenario.start(option.None)
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

pub fn accepting_new_draft_restores_content_and_closes_dialog_test() {
  let scenario =
    new_with_draft()
    |> editor_scenario.dispatch_restore_draft(message.RestoreDraftAccepted)
  let assert model.Ready(editor) = editor_scenario.model(scenario)
  assert editor.snippet.title == "New draft"
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

fn has_restore_open(effects: List(editor_scenario.ObservedEffect)) -> Bool {
  list.contains(
    effects,
    editor_scenario.DialogOpenedNextFrame("editor-page-restore-draft-dialog"),
  )
}
