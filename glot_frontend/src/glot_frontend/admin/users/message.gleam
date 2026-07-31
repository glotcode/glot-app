import glot_core/admin/user_dto
import glot_frontend/admin/users/model.{type DeleteStream, type SaveStream}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  UserLoaded(api_response.Response(user_dto.GetUserResponse))
  UsernameChanged(String)
  RoleChanged(String)
  AccountStateChanged(String)
  AccountStateReasonChanged(String)
  AccountTierChanged(String)
  ResetClicked
  SaveClicked
  DeleteClicked
  DeleteCancelled
  DeleteDialogClosed
  DeleteConfirmed
  SaveFinished(
    Generation(SaveStream),
    api_response.Response(user_dto.UpdateUserResponse),
  )
  DeleteFinished(Generation(DeleteStream), api_response.Response(Nil))
}
