import gleam/option
import glot_core/loadable
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/users/delete_update
import glot_frontend/admin/users/editor_update
import glot_frontend/admin/users/loading_update
import glot_frontend/admin/users/message.{
  AccountStateChanged, AccountStateReasonChanged, AccountTierChanged,
  DeleteCancelled, DeleteClicked, DeleteConfirmed, DeleteDialogClosed,
  DeleteFinished, ResetClicked, RoleChanged, SaveClicked, SaveFinished,
  UserLoaded, UsernameChanged,
}
import glot_frontend/admin/users/model.{DeleteIdle, Model}
import glot_frontend/request_generation
import youid/uuid

pub type Model =
  model.Model

pub type Msg =
  message.Msg

pub fn init(id: uuid.Uuid) -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      id:,
      user: loadable.NotLoaded,
      pending_delete: option.None,
      delete_state: DeleteIdle,
      save_generation: request_generation.initial(),
      delete_generation: request_generation.initial(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) {
  loading_update.ensure_loaded(model)
}

pub fn update(model: Model, msg: Msg) {
  case msg {
    UserLoaded(_) -> loading_update.update(model, msg)
    UsernameChanged(_)
    | RoleChanged(_)
    | AccountStateChanged(_)
    | AccountStateReasonChanged(_)
    | AccountTierChanged(_)
    | ResetClicked
    | SaveClicked
    | SaveFinished(_, _) -> editor_update.update(model, msg)
    DeleteClicked
    | DeleteCancelled
    | DeleteDialogClosed
    | DeleteConfirmed
    | DeleteFinished(_, _) -> delete_update.update(model, msg)
  }
}
