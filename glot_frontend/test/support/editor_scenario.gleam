import gleam/list
import gleam/option
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/managed
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import support/managed_scenario
import youid/uuid.{type Uuid}

/// Managed reads stay pending until a scenario supplies a fixture response.
/// The callback is the same callback used by the production interpreter.
pub type PendingEffect {
  LoadEnvironment(fn(String, settings.EditorSettings) -> message.Msg)
  LoadDraft(
    draft_persistence.Target,
    fn(option.Option(draft.StoredEditorDraft)) -> message.Msg,
  )
  GetSnippet(
    snippet_dto.GetSnippetRequest,
    fn(response.Response(snippet_dto.SnippetResponse)) -> message.Msg,
  )
  RunCode(run.RunRequest, fn(response.Response(run.RunResult)) -> message.Msg)
  GetLanguageVersion(
    run.GetLanguageVersionRequest,
    fn(response.Response(run.RunResult)) -> message.Msg,
  )
  CreateSnippet(
    snippet_dto.CreateSnippetRequest,
    fn(response.Response(snippet_dto.SnippetResponse)) -> message.Msg,
  )
  UpdateSnippet(
    snippet_dto.UpdateSnippetRequest,
    fn(response.Response(snippet_dto.SnippetResponse)) -> message.Msg,
  )
}

/// Browser effects are recorded as data so scenarios can assert user-visible
/// consequences without installing a DOM, navigation, or storage mock.
pub type ObservedEffect {
  DraftSaved(draft_persistence.Write)
  DraftCleared(draft_persistence.Target)
  SettingsSaved(settings.EditorSettings)
  DialogOpened(String)
  DialogOpenedNextFrame(String)
  DialogClosed(String)
  ElementFocused(String)
  Navigated(String)
  MessageScheduled(Int, message.Msg)
}

pub type ScheduledEffect {
  Scheduled(Int, message.Msg)
}

pub opaque type Scenario {
  Scenario(
    core: managed_scenario.Scenario(model.Model, PendingEffect, ObservedEffect),
    current_user_id: option.Option(Uuid),
    scheduled: List(ScheduledEffect),
  )
}

pub fn start(
  initial_model: model.Model,
  current_user_id: option.Option(Uuid),
) -> Scenario {
  Scenario(managed_scenario.new(initial_model), current_user_id, [])
}

pub fn start_with_command(
  initial_model: model.Model,
  current_user_id: option.Option(Uuid),
  initial_command: command.Command(message.Msg),
) -> Scenario {
  start(initial_model, current_user_id)
  |> interpret(initial_command)
}

/// Simulate a user or browser message and interpret every synchronous command.
/// API commands remain pending until completed with one of the response helpers.
pub fn dispatch(scenario: Scenario, msg: message.Msg) -> Scenario {
  let update = fn(model, msg) {
    managed.update(model, msg, scenario.current_user_id)
  }
  let #(next_model, next_command) = update(model(scenario), msg)
  interpret(
    Scenario(
      ..scenario,
      core: managed_scenario.replace_model(scenario.core, next_model),
    ),
    next_command,
  )
}

pub fn dispatch_lifecycle(
  scenario: Scenario,
  msg: message.LifecycleMsg,
) -> Scenario {
  dispatch(scenario, message.Lifecycle(msg))
}

pub fn dispatch_restore_draft(
  scenario: Scenario,
  msg: message.RestoreDraftMsg,
) -> Scenario {
  dispatch(scenario, message.Editor(message.RestoreDraft(msg)))
}

pub fn dispatch_metadata(
  scenario: Scenario,
  msg: message.MetadataMsg,
) -> Scenario {
  dispatch(scenario, message.Editor(message.Metadata(msg)))
}

pub fn dispatch_file(scenario: Scenario, msg: message.FileMsg) -> Scenario {
  dispatch(scenario, message.Editor(message.File(msg)))
}

pub fn dispatch_settings(
  scenario: Scenario,
  msg: message.SettingsMsg,
) -> Scenario {
  dispatch(scenario, message.Editor(message.Settings(msg)))
}

pub fn dispatch_save(scenario: Scenario, msg: message.SaveMsg) -> Scenario {
  dispatch(scenario, message.Editor(message.Save(msg)))
}

pub fn dispatch_snippet_info(
  scenario: Scenario,
  msg: message.SnippetInfoMsg,
) -> Scenario {
  dispatch(scenario, message.Editor(message.SnippetInfo(msg)))
}

pub fn dispatch_execution(
  scenario: Scenario,
  msg: message.ExecutionMsg,
) -> Scenario {
  dispatch(scenario, message.Editor(message.Execution(msg)))
}

pub fn model(scenario: Scenario) -> model.Model {
  managed_scenario.model(scenario.core)
}

/// Return the loaded editor for workflow scenarios whose setup guarantees that
/// lifecycle initialization has completed.
pub fn editor(scenario: Scenario) -> model.Editor {
  let assert model.Ready(editor) = model(scenario)
  editor
}

pub fn pending(scenario: Scenario) -> List(PendingEffect) {
  managed_scenario.pending(scenario.core)
}

pub fn observed(scenario: Scenario) -> List(ObservedEffect) {
  managed_scenario.observed(scenario.core)
}

pub fn scheduled(scenario: Scenario) -> List(ScheduledEffect) {
  scenario.scheduled
}

pub fn deliver_next_scheduled(scenario: Scenario) -> Scenario {
  let assert [Scheduled(_, msg), ..remaining] = scenario.scheduled
  Scenario(..scenario, scheduled: remaining)
  |> dispatch(msg)
}

pub fn respond_to_run(
  scenario: Scenario,
  fixture: response.Response(run.RunResult),
) -> Scenario {
  respond_to_run_at(scenario, 0, fixture)
}

pub fn respond_to_environment(
  scenario: Scenario,
  raw_ssr: String,
  settings: settings.EditorSettings,
) -> Scenario {
  let #(effect, scenario) = take_next_pending(scenario)
  let assert LoadEnvironment(complete) = effect
  dispatch(scenario, complete(raw_ssr, settings))
}

pub fn respond_to_new_draft(
  scenario: Scenario,
  fixture: option.Option(draft.StoredEditorDraft),
) -> Scenario {
  let #(effect, scenario) = take_next_pending(scenario)
  let assert LoadDraft(draft_persistence.NewSnippet(_), complete) = effect
  dispatch(scenario, complete(fixture))
}

pub fn respond_to_get_snippet(
  scenario: Scenario,
  fixture: response.Response(snippet_dto.SnippetResponse),
) -> Scenario {
  let #(effect, scenario) = take_next_pending(scenario)
  let assert GetSnippet(_, complete) = effect
  dispatch(scenario, complete(fixture))
}

/// Complete a particular pending run. This is useful for proving that stale,
/// out-of-order responses cannot overwrite newer state.
pub fn respond_to_run_at(
  scenario: Scenario,
  index: Int,
  fixture: response.Response(run.RunResult),
) -> Scenario {
  let #(effect, scenario) = take_pending_at(scenario, index)
  let assert RunCode(_, complete) = effect
  dispatch(scenario, complete(fixture))
}

pub fn respond_to_language_version(
  scenario: Scenario,
  fixture: response.Response(run.RunResult),
) -> Scenario {
  let #(effect, scenario) = take_next_pending(scenario)
  let assert GetLanguageVersion(_, complete) = effect
  dispatch(scenario, complete(fixture))
}

pub fn respond_to_create(
  scenario: Scenario,
  fixture: response.Response(snippet_dto.SnippetResponse),
) -> Scenario {
  respond_to_create_at(scenario, 0, fixture)
}

pub fn respond_to_create_at(
  scenario: Scenario,
  index: Int,
  fixture: response.Response(snippet_dto.SnippetResponse),
) -> Scenario {
  let #(effect, scenario) = take_pending_at(scenario, index)
  let assert CreateSnippet(_, complete) = effect
  dispatch(scenario, complete(fixture))
}

pub fn respond_to_update(
  scenario: Scenario,
  fixture: response.Response(snippet_dto.SnippetResponse),
) -> Scenario {
  respond_to_update_at(scenario, 0, fixture)
}

pub fn respond_to_update_at(
  scenario: Scenario,
  index: Int,
  fixture: response.Response(snippet_dto.SnippetResponse),
) -> Scenario {
  let #(effect, scenario) = take_pending_at(scenario, index)
  let assert UpdateSnippet(_, complete) = effect
  dispatch(scenario, complete(fixture))
}

pub fn respond_to_existing_draft(
  scenario: Scenario,
  fixture: option.Option(draft.StoredEditorDraft),
) -> Scenario {
  let #(effect, scenario) = take_next_pending(scenario)
  let assert LoadDraft(draft_persistence.ExistingSnippet(_), complete) = effect
  dispatch(scenario, complete(fixture))
}

fn take_next_pending(scenario: Scenario) -> #(PendingEffect, Scenario) {
  take_pending_at(scenario, 0)
}

fn take_pending_at(
  scenario: Scenario,
  index: Int,
) -> #(PendingEffect, Scenario) {
  let #(effect, core) = managed_scenario.take_pending_at(scenario.core, index)
  #(effect, Scenario(..scenario, core:))
}

/// Use at the end of a scenario to reject forgotten or unexpected API work.
pub fn assert_no_pending_effects(scenario: Scenario) -> Nil {
  let assert [] = pending(scenario)
  let assert [] = scenario.scheduled
  Nil
}

pub fn new_editor(lang: language.Language) -> model.Model {
  model.Ready(ready.new(lang, settings.defaults()))
}

fn interpret(
  scenario: Scenario,
  next_command: command.Command(message.Msg),
) -> Scenario {
  case next_command {
    command.None -> scenario
    command.Batch(commands) -> list.fold(commands, scenario, interpret)
    command.LoadEnvironment(complete) ->
      append_pending(scenario, LoadEnvironment(complete))
    command.LoadDraft(target, complete) ->
      append_pending(scenario, LoadDraft(target, complete))
    command.GetSnippet(request, complete) ->
      append_pending(scenario, GetSnippet(request, complete))
    command.RunCode(request, complete) ->
      append_pending(scenario, RunCode(request, complete))
    command.GetLanguageVersion(request, complete) ->
      append_pending(scenario, GetLanguageVersion(request, complete))
    command.CreateSnippet(request, complete) ->
      append_pending(scenario, CreateSnippet(request, complete))
    command.UpdateSnippet(request, complete) ->
      append_pending(scenario, UpdateSnippet(request, complete))
    command.SaveDraft(write) -> append_observed(scenario, DraftSaved(write))
    command.ClearDraft(target) ->
      append_observed(scenario, DraftCleared(target))
    command.SaveSettings(value) ->
      append_observed(scenario, SettingsSaved(value))
    command.OpenDialog(id) -> append_observed(scenario, DialogOpened(id))
    command.OpenDialogNextFrame(id) ->
      append_observed(scenario, DialogOpenedNextFrame(id))
    command.CloseDialog(id) -> append_observed(scenario, DialogClosed(id))
    command.Focus(id) -> append_observed(scenario, ElementFocused(id))
    command.Navigate(path) -> append_observed(scenario, Navigated(path))
    command.Schedule(milliseconds, msg) -> {
      let scenario =
        Scenario(
          ..scenario,
          scheduled: list.append(scenario.scheduled, [
            Scheduled(milliseconds, msg),
          ]),
        )
      append_observed(scenario, MessageScheduled(milliseconds, msg))
    }
  }
}

fn append_pending(scenario: Scenario, effect: PendingEffect) -> Scenario {
  Scenario(
    ..scenario,
    core: managed_scenario.append_pending(scenario.core, effect),
  )
}

fn append_observed(scenario: Scenario, effect: ObservedEffect) -> Scenario {
  Scenario(
    ..scenario,
    core: managed_scenario.append_observed(scenario.core, effect),
  )
}
