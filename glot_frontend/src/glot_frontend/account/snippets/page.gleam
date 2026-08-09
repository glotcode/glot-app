import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_frontend/account/snippets/command
import glot_frontend/account/snippets/interpreter
import glot_frontend/account/snippets/managed
import glot_frontend/account/snippets/message
import glot_frontend/account/snippets/model
import glot_frontend/account/snippets/production_ports
import glot_frontend/account/snippets/view as snippets_view
import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub type Model =
  model.Model

pub type Msg =
  message.Msg

pub type Request =
  model.Request

pub fn init(
  after after: option.Option(String),
  before before: option.Option(String),
  language language_filter: option.Option(String),
) -> #(Model, Effect(Msg)) {
  let #(model, next_command) =
    managed.init(after:, before:, language: language_filter)
  #(model, interpreter.run(next_command, using: production_ports.new()))
}

pub fn init_managed(
  after after: option.Option(String),
  before before: option.Option(String),
  language language_filter: option.Option(String),
) -> #(Model, command.Command(Msg)) {
  managed.init(after:, before:, language: language_filter)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let #(model, next_command) = managed.update(model, msg)
  #(model, interpreter.run(next_command, using: production_ports.new()))
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
