import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/existing_editor_transition
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/settings
import glot_web/page/editor as editor_ssr
import support/editor_fixture

pub fn response_builds_the_editor_and_required_follow_up_commands_test() {
  let fixture =
    editor_fixture.snippet_with(
      slug: "transition",
      owner: editor_fixture.owner_id(),
      title: "",
      visibility: snippet_model.Unlisted,
      files: [snippet_model.File("main.js", "source")],
      stdin: "",
      run_instructions: option.None,
    )
  let #(next_model, next_command) =
    existing_editor_transition.from_response(
      fixture,
      settings.EditorSettings(settings.VimBindings),
    )
  let assert model.Ready(editor) = next_model

  assert editor.snippet.slug == option.Some("transition")
  assert editor.snippet.title == "Hello World"
  assert editor.snippet.stdin == option.None
  assert editor.editor_settings == settings.EditorSettings(settings.VimBindings)

  let assert command.Batch([
    command.GetLanguageVersion(version_request, version_complete),
    command.LoadDraft(
      draft_persistence.ExistingSnippet("transition"),
      draft_complete,
    ),
  ]) = next_command
  assert version_request.language == language.JavaScript
  let assert message.Editor(message.Execution(message.VersionRunFinished(
    language.JavaScript,
    _,
  ))) = version_complete(editor_fixture.api_failure("unavailable"))
  let assert message.Editor(message.RestoreDraft(message.ExistingDraftLoaded(
    "transition",
    updated_at,
    option.None,
  ))) = draft_complete(option.None)
  assert updated_at == fixture.updated_at
}

pub fn ssr_and_api_data_produce_the_same_ready_editor_test() {
  let fixture = editor_fixture.snippet("shared-transition", "source")
  let settings = settings.EditorSettings(settings.EmacsBindings)
  let #(from_api, _) =
    existing_editor_transition.from_response(fixture, settings)
  let assert editor_ssr.ExistingSnippet(ssr) = editor_ssr.from_snippet(fixture)
  let assert Ok(#(from_ssr, _)) =
    existing_editor_transition.from_ssr(ssr, settings)

  assert from_ssr == from_api
}

pub fn incomplete_ssr_is_rejected_at_the_transition_boundary_test() {
  let fixture = editor_fixture.snippet("incomplete", "source")
  let assert editor_ssr.ExistingSnippet(ssr) = editor_ssr.from_snippet(fixture)
  let incomplete = editor_ssr.EditorModel(..ssr, updated_at: option.None)

  assert existing_editor_transition.from_ssr(incomplete, settings.defaults())
    == Error("Could not load snippet.")
}
