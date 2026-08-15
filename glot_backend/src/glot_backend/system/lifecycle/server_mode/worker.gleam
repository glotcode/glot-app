import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/supervision
import glot_backend/system/lifecycle/server_mode/model.{type Mode}

pub type Message {
  SetMode(mode: Mode)
  SetModeAndWait(mode: Mode, reply: process.Subject(Nil))
  GetMode(reply: process.Subject(Mode))
}

type State {
  State(mode: Mode)
}

const call_timeout_ms = 100

pub fn start(name: process.Name(Message)) {
  start_in(name, model.Running)
}

pub fn start_in(name: process.Name(Message), mode: Mode) {
  actor.new(State(mode: mode))
  |> actor.named(name)
  |> actor.on_message(handle_message)
  |> actor.start
}

pub fn supervised(name: process.Name(Message)) {
  supervision.worker(fn() { start(name) })
}

pub fn supervised_in(name: process.Name(Message), mode: Mode) {
  supervision.worker(fn() { start_in(name, mode) })
}

pub fn get_mode(subject: process.Subject(Message)) -> Mode {
  process.call(subject, call_timeout_ms, GetMode)
}

pub fn enter_maintenance(subject: process.Subject(Message)) -> Nil {
  process.send(subject, SetMode(model.Maintenance))
}

pub fn enter_running(subject: process.Subject(Message)) -> Nil {
  process.send(subject, SetMode(model.Running))
}

pub fn enter_shutting_down(subject: process.Subject(Message)) -> Nil {
  process.call(subject, call_timeout_ms, fn(reply) {
    SetModeAndWait(model.ShuttingDown, reply)
  })
}

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    SetMode(mode) -> actor.continue(State(mode: mode))
    SetModeAndWait(mode, reply) -> {
      process.send(reply, Nil)
      actor.continue(State(mode: mode))
    }
    GetMode(reply) -> {
      process.send(reply, state.mode)
      actor.continue(state)
    }
  }
}
