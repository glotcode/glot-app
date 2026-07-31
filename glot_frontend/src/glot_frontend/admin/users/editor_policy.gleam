import gleam/option
import gleam/result
import gleam/string
import glot_core/admin/user_dto
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/loadable
import glot_core/validation_error
import glot_frontend/admin/users/model.{
  type Model, type UserEditor, Model, UserEditor, UserFields, UserMetadata,
}
import glot_frontend/request_generation
import glot_frontend/ui/mutation

pub fn update_model(
  model: Model,
  update: fn(UserEditor) -> UserEditor,
) -> Model {
  case model.user {
    loadable.Loaded(editor) ->
      Model(
        ..model,
        user: loadable.Loaded(update(editor)),
        save_generation: request_generation.next(model.save_generation),
      )
    _ -> model
  }
}

pub fn from_response(user: user_dto.UserDetailResponse) -> UserEditor {
  let fields =
    UserFields(
      username: user.username,
      role: user.role,
      account_state: user.account_state,
      account_state_reason: option.unwrap(user.account_state_reason, ""),
      account_tier: user.account_tier,
    )

  UserEditor(
    id: user.id,
    account_id: user.account_id,
    email: user.email,
    saved: fields,
    draft: fields,
    metadata: UserMetadata(
      delete_job_id: user.delete_job_id,
      delete_scheduled_at: user.delete_scheduled_at,
      last_login_at: user.last_login_at,
      created_at: user.created_at,
      updated_at: user.updated_at,
    ),
    state: mutation.Idle,
  )
}

pub fn to_request(
  editor: UserEditor,
) -> Result(user_dto.UpdateUserRequest, String) {
  let username = string.trim(editor.draft.username)

  use _ <- result.try(
    user_model.validate_username(username)
    |> result.map_error(validation_error.message),
  )

  Ok(user_dto.UpdateUserRequest(
    id: editor.id,
    username: username,
    role: editor.draft.role,
    account_state: editor.draft.account_state,
    account_state_reason: account_state_reason_value(
      editor.draft.account_state,
      editor.draft.account_state_reason,
    ),
    account_tier: editor.draft.account_tier,
  ))
}

fn account_state_reason_value(
  account_state: account_model.AccountState,
  value: String,
) -> option.Option(String) {
  case account_state {
    account_model.Active -> option.None
    account_model.ReadOnly | account_model.Suspended ->
      case string.trim(value) {
        "" -> option.None
        trimmed -> option.Some(trimmed)
      }
  }
}
