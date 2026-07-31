import gleam/option
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/loadable
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/users/editor_policy
import glot_frontend/admin/users/message.{
  AccountStateChanged, AccountStateReasonChanged, AccountTierChanged,
  ResetClicked, RoleChanged, SaveClicked, SaveFinished, UsernameChanged,
}
import glot_frontend/admin/users/model.{
  type Model, DeleteIdle, Model, UserEditor, UserFields,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation
import glot_frontend/ui/mutation

pub fn update(model: Model, msg: message.Msg) {
  case msg {
    UsernameChanged(value) ->
      change(model, fn(editor) {
        UserEditor(
          ..editor,
          draft: UserFields(..editor.draft, username: value),
          state: mutation.Idle,
        )
      })
    RoleChanged(value) ->
      case user_model.role_from_string(value) {
        option.Some(role) ->
          change(model, fn(editor) {
            UserEditor(
              ..editor,
              draft: UserFields(..editor.draft, role:),
              state: mutation.Idle,
            )
          })
        option.None -> #(model, admin_effect.none())
      }
    AccountStateChanged(value) ->
      case account_model.account_state_from_string(value) {
        option.Some(account_state) ->
          change(model, fn(editor) {
            let reason = case account_state {
              account_model.Active -> ""
              account_model.ReadOnly | account_model.Suspended ->
                editor.draft.account_state_reason
            }
            UserEditor(
              ..editor,
              draft: UserFields(
                ..editor.draft,
                account_state:,
                account_state_reason: reason,
              ),
              state: mutation.Idle,
            )
          })
        option.None -> #(model, admin_effect.none())
      }
    AccountStateReasonChanged(value) ->
      change(model, fn(editor) {
        UserEditor(
          ..editor,
          draft: UserFields(..editor.draft, account_state_reason: value),
          state: mutation.Idle,
        )
      })
    AccountTierChanged(value) ->
      case account_model.account_tier_from_string(value) {
        option.Some(account_tier) ->
          change(model, fn(editor) {
            UserEditor(
              ..editor,
              draft: UserFields(..editor.draft, account_tier:),
              state: mutation.Idle,
            )
          })
        option.None -> #(model, admin_effect.none())
      }
    ResetClicked ->
      change(model, fn(editor) {
        UserEditor(..editor, draft: editor.saved, state: mutation.Idle)
      })
    SaveClicked -> save(model)
    SaveFinished(generation, _) if generation != model.save_generation -> #(
      model,
      admin_effect.none(),
    )
    SaveFinished(_, result) ->
      case result {
        api_response.Success(response) -> #(
          Model(
            ..model,
            user: loadable.Loaded(editor_policy.from_response(response.user)),
            pending_delete: option.None,
            delete_state: DeleteIdle,
          ),
          admin_effect.none(),
        )
        api_response.ApiFailure(error) ->
          save_failed(model, api_response.error_message(error))
        api_response.HttpFailure(_) ->
          save_failed(model, "Could not update user.")
      }
    _ -> #(model, admin_effect.none())
  }
}

fn change(model: Model, update_editor) {
  #(editor_policy.update_model(model, update_editor), admin_effect.none())
}

fn save(model: Model) {
  case model.user {
    loadable.Loaded(editor) ->
      case editor_policy.to_request(editor) {
        Ok(request) -> {
          let generation = request_generation.next(model.save_generation)
          #(
            Model(
              ..editor_policy.update_model(model, fn(current) {
                UserEditor(..current, state: mutation.Saving)
              }),
              save_generation: generation,
            ),
            admin_effect.update_admin_user(request, fn(result) {
              SaveFinished(generation, result)
            }),
          )
        }
        Error(message) -> save_failed(model, message)
      }
    _ -> #(model, admin_effect.none())
  }
}

fn save_failed(model: Model, message: String) {
  change(model, fn(editor) {
    UserEditor(..editor, state: mutation.SaveError(message))
  })
}
