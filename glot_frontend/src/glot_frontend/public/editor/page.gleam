import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/route
import glot_frontend/public/editor/command
import glot_frontend/public/editor/initialization
import glot_frontend/public/editor/interpreter as editor_interpreter
import glot_frontend/public/editor/message.{type Msg}
import glot_frontend/public/editor/model.{
  type InitTarget, type Model, type RealModel, ExistingEditor, Initializing,
  LoadError, LoadingSnippet, NewEditor, SupportedLanguage, UnsupportedLanguage,
}
import glot_frontend/public/editor/production_ports
import glot_frontend/public/editor/quick_actions as editor_quick_actions
import glot_frontend/public/editor/update as editor_update
import glot_frontend/public/editor/view as editor_view
import glot_web/page/editor as editor_ssr
import glot_web/page/seo
import glot_web/page/top_bar
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import youid/uuid.{type Uuid}

pub fn init_new(language: String) -> #(Model, Effect(Msg)) {
  let #(model, next_command) = init_managed(NewEditor(language))
  #(model, interpret(next_command))
}

pub fn init_existing(slug: String) -> #(Model, Effect(Msg)) {
  let #(model, next_command) = init_managed(ExistingEditor(slug))
  #(model, interpret(next_command))
}

pub fn init_managed(target: InitTarget) -> #(Model, command.Command(Msg)) {
  initialization.start(target)
}

pub fn affects_metadata(msg: Msg) -> Bool {
  message.affects_metadata(msg)
}

pub fn update(
  model: Model,
  msg: Msg,
  current_user_id: option.Option(Uuid),
) -> #(Model, Effect(Msg)) {
  let #(model, command) = update_managed(model, msg, current_user_id)
  #(model, interpret(command))
}

pub fn update_managed(
  model: Model,
  msg: Msg,
  current_user_id: option.Option(Uuid),
) -> #(Model, command.Command(Msg)) {
  case initialization.update(model, msg) {
    option.Some(result) -> result
    option.None -> editor_update.update(model, msg, current_user_id)
  }
}

fn interpret(command: command.Command(Msg)) -> Effect(Msg) {
  editor_interpreter.run(command, using: production_ports.new())
}

pub fn view(
  model: Model,
  current_user_id: option.Option(Uuid),
  now: Timestamp,
) -> Element(Msg) {
  editor_view.view(model, current_user_id, now)
}

pub fn metadata(model: Model) -> seo.Metadata {
  case model {
    Initializing(target) -> initializing_metadata(target)
    UnsupportedLanguage(language_slug) ->
      editor_ssr.metadata(editor_ssr.UnsupportedLanguage(language_slug))
    LoadingSnippet(slug, _, _) ->
      seo.metadata(
        title: "Loading snippet | glot.io",
        description: "Loading a code snippet on glot.io.",
        canonical_path: route.to_string(route.Public(route.Snippet(slug))),
        index: False,
        open_graph_type: "website",
      )
    LoadError(message) -> editor_ssr.metadata(editor_ssr.LoadError(message))
    SupportedLanguage(model) -> editor_ssr.metadata(to_ssr_view_model(model))
  }
}

fn to_ssr_view_model(model: RealModel) -> editor_ssr.ViewModel {
  let ssr_model =
    editor_ssr.EditorModel(
      slug: model.slug,
      owner_user_id: model.owner_user_id,
      owner_username: model.owner_username,
      title: model.title,
      language: model.language,
      visibility: option.Some(model.visibility),
      created_at: model.created_at,
      updated_at: model.updated_at,
      run_instructions_override: model.run_instructions_override,
      files: model.files,
      stdin: model.stdin,
    )

  case model.slug {
    option.Some(_) -> editor_ssr.ExistingSnippet(ssr_model)
    option.None -> editor_ssr.NewSnippet(ssr_model)
  }
}

pub fn quick_actions(
  model: Model,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  editor_quick_actions.actions(model, current_user_id)
}

fn initializing_metadata(target: InitTarget) -> seo.Metadata {
  let canonical_path = case target {
    NewEditor(language) ->
      route.to_string(route.Public(route.NewSnippet(language)))
    ExistingEditor(slug) -> route.to_string(route.Public(route.Snippet(slug)))
  }
  seo.metadata(
    title: "Loading editor | glot.io",
    description: "Loading the glot.io code editor.",
    canonical_path: canonical_path,
    index: False,
    open_graph_type: "website",
  )
}
