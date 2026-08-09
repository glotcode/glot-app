import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_frontend/public/snippets/command
import glot_frontend/public/snippets/interpreter
import glot_frontend/public/snippets/managed
import glot_frontend/public/snippets/message.{type Msg}
import glot_frontend/public/snippets/model.{type Model}
import glot_frontend/public/snippets/production_ports
import glot_frontend/public/snippets/view as snippets_view
import glot_web/page/seo
import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub fn init(
  after after: option.Option(String),
  before before: option.Option(String),
  username username: option.Option(String),
  language language_filter: option.Option(String),
) -> #(Model, Effect(Msg)) {
  let #(model, command) =
    init_managed(after:, before:, username:, language: language_filter)
  #(model, interpret(command))
}

pub fn init_managed(
  after after: option.Option(String),
  before before: option.Option(String),
  username username: option.Option(String),
  language language_filter: option.Option(String),
) -> #(Model, command.Command(Msg)) {
  managed.init(after:, before:, username:, language: language_filter)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let #(model, command) = update_managed(model, msg)
  #(model, interpret(command))
}

pub fn update_managed(
  model: Model,
  msg: Msg,
) -> #(Model, command.Command(Msg)) {
  managed.update(model, msg)
}

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  snippets_view.view(model, now)
}

pub fn metadata(model: Model, canonical_path: String) -> seo.Metadata {
  snippets_view.metadata(model, canonical_path)
}

fn interpret(command: command.Command(Msg)) -> Effect(Msg) {
  interpreter.run(command, using: production_ports.new())
}
