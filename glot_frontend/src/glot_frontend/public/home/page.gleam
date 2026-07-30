import glot_frontend/public/home/managed
import glot_frontend/public/home/message
import glot_frontend/public/home/model
import glot_frontend/public/home/view as home_view
import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub type Model =
  model.Model

pub type Msg =
  message.Msg

pub fn init() -> #(Model, Effect(Msg)) {
  #(managed.init(), effect.none())
}

pub fn init_managed() -> Model {
  managed.init()
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  #(managed.update(model, msg), effect.none())
}

pub fn update_managed(model: Model, msg: Msg) -> Model {
  managed.update(model, msg)
}

pub fn view(model: Model) -> Element(Msg) {
  home_view.view(model)
}
