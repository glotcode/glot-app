import gleam/option
import glot_core/admin/account_dto
import glot_core/loadable
import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/users/constants
import glot_frontend/admin/users/message.{
  DeleteCancelled, DeleteClicked, DeleteConfirmed, DeleteDialogClosed,
  DeleteFinished,
}
import glot_frontend/admin/users/model.{type Model, DeleteIdle, Deleting, Model}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation

pub fn update(model: Model, msg: message.Msg) {
  case msg {
    DeleteClicked ->
      case model.user {
        loadable.Loaded(editor) -> #(
          Model(..model, pending_delete: option.Some(editor)),
          admin_effect.OpenDialog(constants.delete_dialog_id),
        )
        _ -> #(model, admin_effect.none())
      }
    DeleteCancelled -> #(
      model,
      admin_effect.CloseDialog(constants.delete_dialog_id),
    )
    DeleteDialogClosed -> #(
      Model(..model, pending_delete: option.None),
      admin_effect.none(),
    )
    DeleteConfirmed -> confirm(model)
    DeleteFinished(generation, _) if generation != model.delete_generation -> #(
      model,
      admin_effect.none(),
    )
    DeleteFinished(_, result) ->
      case result {
        api_response.Success(_) -> #(
          Model(..model, pending_delete: option.None, delete_state: DeleteIdle),
          navigate_to_users(),
        )
        api_response.ApiFailure(error) ->
          failed(model, api_response.error_message(error))
        api_response.HttpFailure(_) ->
          failed(model, "Could not delete account.")
      }
    _ -> #(model, admin_effect.none())
  }
}

fn confirm(model: Model) {
  case model.pending_delete {
    option.Some(editor) -> {
      let generation = request_generation.next(model.delete_generation)
      #(
        Model(..model, delete_state: Deleting, delete_generation: generation),
        admin_effect.batch([
          admin_effect.CloseDialog(constants.delete_dialog_id),
          admin_effect.delete_admin_account(
            account_dto.DeleteAccountRequest(user_id: editor.id),
            fn(result) { DeleteFinished(generation, result) },
          ),
        ]),
      )
    }
    option.None -> #(model, admin_effect.none())
  }
}

fn failed(model: Model, message: String) {
  #(
    Model(
      ..model,
      user: loadable.LoadError(message),
      pending_delete: option.None,
      delete_state: DeleteIdle,
    ),
    admin_effect.none(),
  )
}

fn navigate_to_users() {
  admin_effect.Navigate(route.to_string(route.Admin(route.AdminUsers)))
}
