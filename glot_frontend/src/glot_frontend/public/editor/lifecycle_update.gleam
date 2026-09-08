import glot_core/language
import glot_core/snippet/snippet_dto
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/code_editor/update as code_editor_update
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/existing_editor_transition
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/lifecycle_resolution.{
  type Resolution, Failed, FetchExisting, StartExisting, StartNew, Unsupported,
}
import glot_frontend/public/editor/code_editor/browser_command as code_editor_browser_command
import glot_frontend/public/editor/code_editor/message as code_editor_message
import glot_frontend/public/editor/message.{
  type LifecycleMsg, type Msg, CodeEditor, Editor, EnvironmentLoaded, Execution,
  Lifecycle, NewDraftLoaded, RestoreDraft, SnippetLoaded,
  SnippetLoadingDelayElapsed,
}
import glot_frontend/public/editor/model.{
  type Model, Lifecycle as LifecycleModel, Ready,
}
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/environment
import glot_frontend/ui/delayed_loading

pub fn start(target: lifecycle.Target) -> #(Model, command.Command(Msg)) {
  #(
    LifecycleModel(lifecycle.Initializing(target)),
    command.LoadEnvironment(fn(raw_ssr, found) {
      Lifecycle(EnvironmentLoaded(target, raw_ssr, found))
    }),
  )
}

pub fn update(
  model: lifecycle.Model,
  msg: LifecycleMsg,
) -> #(Model, command.Command(Msg)) {
  case model, msg {
    lifecycle.Initializing(current_target),
      EnvironmentLoaded(target, raw_ssr, found)
      if current_target == target
    ->
      lifecycle_resolution.resolve(target, raw_ssr)
      |> execute(found)

    lifecycle.LoadingSnippet(current_slug, found, _),
      SnippetLoaded(slug, result)
    -> {
      case current_slug == slug, result {
        False, _ -> continue(model)
        True, api_response.Success(response) ->
          existing_editor_transition.from_response(response, found)
        True, api_response.ApiFailure(error) ->
          continue(lifecycle.LoadError(api_response.error_message(error)))
        True, api_response.HttpFailure(_) ->
          continue(lifecycle.LoadError("Could not load snippet."))
      }
    }

    lifecycle.LoadingSnippet(current_slug, found, loading_indicator),
      SnippetLoadingDelayElapsed(slug, generation)
    ->
      case current_slug == slug {
        True -> #(
          LifecycleModel(lifecycle.LoadingSnippet(
            current_slug,
            found,
            delayed_loading.reveal(loading_indicator, generation),
          )),
          command.none(),
        )
        False -> continue(model)
      }

    _, _ -> continue(model)
  }
}

fn continue(model: lifecycle.Model) -> #(Model, command.Command(Msg)) {
  #(LifecycleModel(model), command.none())
}

fn execute(
  resolution: Resolution,
  found: environment.Environment,
) -> #(Model, command.Command(Msg)) {
  case resolution {
    StartNew(language) -> init_supported_new(language, found)
    StartExisting(model) ->
      case existing_editor_transition.from_ssr(model, found) {
        Ok(transition) -> transition
        Error(message) -> continue(lifecycle.LoadError(message))
      }
    FetchExisting(slug) ->
      init_existing_after_environment(slug, found)
    Unsupported(language_slug) ->
      continue(lifecycle.UnsupportedLanguage(language_slug))
    Failed(message) -> continue(lifecycle.LoadError(message))
  }
}

fn init_existing_after_environment(
  slug: String,
  found: environment.Environment,
) -> #(Model, command.Command(Msg)) {
  let #(loading_indicator, generation) =
    delayed_loading.begin(delayed_loading.idle())
  #(
    LifecycleModel(lifecycle.LoadingSnippet(slug, found, loading_indicator)),
    command.batch([
      command.GetSnippet(snippet_dto.GetSnippetRequest(slug: slug), fn(result) {
        Lifecycle(SnippetLoaded(slug, result))
      }),
      command.Schedule(
        delayed_loading.delay(),
        Lifecycle(SnippetLoadingDelayElapsed(slug, generation)),
      ),
    ]),
  )
}

fn init_supported_new(
  language: language.Language,
  found: environment.Environment,
) -> #(Model, command.Command(Msg)) {
  let model = Ready(ready.new(language, found))
  let language_slug = language.to_string(language)
  let Ready(editor) = model

  #(
    model,
    command.batch([
      command.CodeEditor(code_editor_update.sync(editor.workspace.editor)),
      run_instructions.version_run_command(language)
        |> command.map(fn(msg) { Editor(Execution(msg)) }),
      command.CodeEditor(
        code_editor_browser_command.Measure(fn(
          line_height,
          height,
          width,
          char_width,
        ) {
          Editor(
            CodeEditor(code_editor_message.Measured(
              line_height:,
              height:,
              width:,
              char_width:,
            )),
          )
        }),
      ),
      command.LoadDraft(draft_persistence.NewSnippet(language_slug), fn(stored) {
        Editor(RestoreDraft(NewDraftLoaded(language_slug, stored)))
      }),
    ]),
  )
}
