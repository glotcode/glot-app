import glot_frontend/public/home/message.{type Msg, Increment}
import glot_frontend/public/home/model.{type Model, Model}

pub fn init() -> Model {
  Model
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> model
  }
}
