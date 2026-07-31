import gleam/option
import glot_frontend/public/editor/command
import glot_frontend/public/editor/lifecycle.{type Target}
import glot_frontend/public/editor/lifecycle_update
import glot_frontend/public/editor/message.{type Msg, Editor, Lifecycle}
import glot_frontend/public/editor/model.{
  type Model, Lifecycle as LifecycleModel, Ready,
}
import glot_frontend/public/editor/update as editor_update
import youid/uuid.{type Uuid}

pub fn init(target: Target) -> #(Model, command.Command(Msg)) {
  lifecycle_update.start(target)
}

pub fn update(
  model: Model,
  msg: Msg,
  current_user_id: option.Option(Uuid),
) -> #(Model, command.Command(Msg)) {
  case model, msg {
    Ready(editor), Editor(msg) -> {
      let #(editor, next) = editor_update.update(editor, msg, current_user_id)
      #(Ready(editor), command.map(next, Editor))
    }
    Ready(_), Lifecycle(_) -> #(model, command.none())
    LifecycleModel(model), Lifecycle(msg) -> lifecycle_update.update(model, msg)
    LifecycleModel(_), Editor(_) -> #(model, command.none())
  }
}
