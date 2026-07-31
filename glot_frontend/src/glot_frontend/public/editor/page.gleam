import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_frontend/public/editor/command
import glot_frontend/public/editor/interpreter as editor_interpreter
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/managed
import glot_frontend/public/editor/message.{type Msg}
import glot_frontend/public/editor/metadata as editor_metadata
import glot_frontend/public/editor/model.{type Model}
import glot_frontend/public/editor/production_ports
import glot_frontend/public/editor/quick_actions as editor_quick_actions
import glot_frontend/public/editor/view as editor_view
import glot_web/page/seo
import glot_web/page/top_bar
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import youid/uuid.{type Uuid}

pub fn init_new(language: String) -> #(Model, Effect(Msg)) {
  let #(model, next_command) = init_managed(lifecycle.NewEditor(language))
  #(model, interpret(next_command))
}

pub fn init_existing(slug: String) -> #(Model, Effect(Msg)) {
  let #(model, next_command) = init_managed(lifecycle.ExistingEditor(slug))
  #(model, interpret(next_command))
}

pub fn init_managed(
  target: lifecycle.Target,
) -> #(Model, command.Command(Msg)) {
  managed.init(target)
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
  managed.update(model, msg, current_user_id)
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
  editor_metadata.metadata(model)
}

pub fn quick_actions(
  model: Model,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  editor_quick_actions.actions(model, current_user_id)
}
