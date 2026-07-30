import gleam/time/timestamp.{type Timestamp}
import glot_frontend/account/command
import glot_frontend/account/interpreter
import glot_frontend/account/managed
import glot_frontend/account/message.{type Msg}
import glot_frontend/account/model.{type Model}
import glot_frontend/account/production_ports
import glot_frontend/account/view as account_view
import glot_frontend/app/event as app_event
import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub fn init() -> #(Model, Effect(Msg)) {
  let #(model, command) = init_managed()
  #(model, interpret(command))
}

pub fn init_managed() -> #(Model, command.Command(Msg)) {
  managed.init()
}

pub fn update(
  model: Model,
  msg: Msg,
) -> #(Model, Effect(Msg), app_event.AppEvent) {
  let #(model, command, event) = managed.update(model, msg)
  #(model, interpret(command), event)
}

pub fn update_managed(
  model: Model,
  msg: Msg,
) -> #(Model, command.Command(Msg), app_event.AppEvent) {
  managed.update(model, msg)
}

fn interpret(command: command.Command(Msg)) -> Effect(Msg) {
  interpreter.run(command, using: production_ports.new())
}

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  account_view.view(model, now)
}

pub fn should_show_passkey_section(passkey_supported: Bool) -> Bool {
  passkey_supported
}
