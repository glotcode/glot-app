import gleam/option
import gleam/string
import glot_core/language
import glot_frontend/api/response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/lifecycle_update
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/settings
import glot_frontend/request_generation
import glot_frontend/ui/delayed_loading
import rsvp
import support/editor_fixture

pub fn start_loads_the_environment_for_the_correlated_target_test() {
  let target = lifecycle.NewEditor("javascript")
  let #(initial, next_command) = lifecycle_update.start(target)
  assert initial == model.Lifecycle(lifecycle.Initializing(target))
  let assert command.LoadEnvironment(complete) = next_command

  assert complete("ssr", settings.EditorSettings(settings.VimBindings))
    == message.Lifecycle(message.EnvironmentLoaded(
      target,
      "ssr",
      settings.EditorSettings(settings.VimBindings),
    ))
}

pub fn matching_new_environment_starts_the_editor_and_follow_up_reads_test() {
  let target = lifecycle.NewEditor("javascript")
  let #(next_model, next_command) =
    lifecycle_update.update(
      lifecycle.Initializing(target),
      message.EnvironmentLoaded(
        target,
        "",
        settings.EditorSettings(settings.VimBindings),
      ),
    )
  let assert model.Ready(editor) = next_model
  assert editor.snippet.language == language.JavaScript
  assert editor.editor_settings == settings.EditorSettings(settings.VimBindings)
  let assert command.Batch([
    command.GetLanguageVersion(version_request, version_complete),
    command.LoadDraft(
      draft_persistence.NewSnippet("javascript"),
      draft_complete,
    ),
  ]) = next_command
  assert version_request.language == language.JavaScript
  let assert message.Editor(message.Execution(message.VersionRunFinished(
    language.JavaScript,
    _,
  ))) = version_complete(editor_fixture.api_failure("unavailable"))
  assert draft_complete(option.None)
    == message.Editor(
      message.RestoreDraft(message.NewDraftLoaded("javascript", option.None)),
    )
}

pub fn matching_existing_environment_starts_correlated_fetch_and_delay_test() {
  let #(loading, next_command) = begin_existing("existing")
  let assert lifecycle.LoadingSnippet(slug, editor_settings, indicator) =
    loading
  assert slug == "existing"
  assert editor_settings == settings.defaults()
  assert !delayed_loading.is_visible(indicator)
  let assert command.Batch([
    command.GetSnippet(request, complete),
    command.Schedule(delay, message.Lifecycle(delay_message)),
  ]) = next_command
  assert request.slug == "existing"
  assert delay == delayed_loading.delay()
  let assert message.Lifecycle(message.SnippetLoaded(
    "existing",
    response.Success(_),
  )) = complete(response.Success(editor_fixture.snippet("existing", "source")))

  let #(revealed, reveal_command) =
    lifecycle_update.update(loading, delay_message)
  let assert model.Lifecycle(lifecycle.LoadingSnippet(_, _, revealed_indicator)) =
    revealed
  assert delayed_loading.is_visible(revealed_indicator)
  assert reveal_command == command.None
}

pub fn stale_environment_snippet_and_delay_messages_are_ignored_test() {
  let target = lifecycle.NewEditor("javascript")
  let initializing = lifecycle.Initializing(target)
  assert lifecycle_update.update(
      initializing,
      message.EnvironmentLoaded(
        lifecycle.ExistingEditor("other"),
        "",
        settings.defaults(),
      ),
    )
    == #(model.Lifecycle(initializing), command.None)

  let #(loading, _) = begin_existing("current")
  assert lifecycle_update.update(
      loading,
      message.SnippetLoaded(
        "other",
        response.Success(editor_fixture.snippet("other", "stale")),
      ),
    )
    == #(model.Lifecycle(loading), command.None)
  let #(unchanged, delay_command) =
    lifecycle_update.update(
      loading,
      message.SnippetLoadingDelayElapsed(
        "current",
        request_generation.initial(),
      ),
    )
  let assert model.Lifecycle(lifecycle.LoadingSnippet(_, _, indicator)) =
    unchanged
  assert !delayed_loading.is_visible(indicator)
  assert delay_command == command.None
}

pub fn matching_snippet_response_uses_the_existing_editor_transition_test() {
  let #(loading, _) = begin_existing("loaded")
  let fixture = editor_fixture.snippet("loaded", "source")
  let #(next_model, next_command) =
    lifecycle_update.update(
      loading,
      message.SnippetLoaded("loaded", response.Success(fixture)),
    )
  let assert model.Ready(editor) = next_model
  assert editor.snippet.slug == option.Some("loaded")
  assert editor.snippet.files == fixture.data.files
  let assert command.Batch([
    command.GetLanguageVersion(_, _),
    command.LoadDraft(draft_persistence.ExistingSnippet("loaded"), _),
  ]) = next_command
}

pub fn matching_snippet_failures_become_stable_terminal_states_test() {
  let #(loading, _) = begin_existing("failed")
  let #(api_failed, api_command) =
    lifecycle_update.update(
      loading,
      message.SnippetLoaded(
        "failed",
        editor_fixture.api_failure("Snippet unavailable."),
      ),
    )
  let assert model.Lifecycle(lifecycle.LoadError(api_error)) = api_failed
  assert string.contains(api_error, "Snippet unavailable.")
  assert string.contains(api_error, "Request ID:")
  assert api_command == command.None

  let #(http_failed, http_command) =
    lifecycle_update.update(
      loading,
      message.SnippetLoaded("failed", response.HttpFailure(rsvp.BadBody)),
    )
  assert http_failed
    == model.Lifecycle(lifecycle.LoadError("Could not load snippet."))
  assert http_command == command.None
}

pub fn messages_outside_the_matching_lifecycle_state_are_ignored_test() {
  let terminal = lifecycle.LoadError("failed")
  assert lifecycle_update.update(
      terminal,
      message.EnvironmentLoaded(
        lifecycle.NewEditor("javascript"),
        "",
        settings.defaults(),
      ),
    )
    == #(model.Lifecycle(terminal), command.None)
}

fn begin_existing(
  slug: String,
) -> #(lifecycle.Model, command.Command(message.Msg)) {
  let target = lifecycle.ExistingEditor(slug)
  let #(next_model, next_command) =
    lifecycle_update.update(
      lifecycle.Initializing(target),
      message.EnvironmentLoaded(target, "", settings.defaults()),
    )
  let assert model.Lifecycle(loading) = next_model
  #(loading, next_command)
}
