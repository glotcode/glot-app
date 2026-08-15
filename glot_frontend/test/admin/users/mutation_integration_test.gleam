import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/admin/user_dto
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/loadable
import glot_frontend/admin/command
import glot_frontend/admin/effect/users
import glot_frontend/admin/users/editor_policy as user_policy
import glot_frontend/admin/users/managed as user_managed
import glot_frontend/admin/users/message as user_message
import glot_frontend/admin/users/model as user_detail_model
import glot_frontend/admin/users/view as user_view
import glot_frontend/api/response
import glot_frontend/ui/mutation
import lustre/element
import youid/uuid

pub fn user_mutation_covers_reset_failure_retry_and_success_test() {
  let fixture = user_fixture("fixture-user")
  let #(base, _) = user_managed.init(fixture.id)
  let initial =
    user_detail_model.Model(
      ..base,
      user: loadable.Loaded(user_policy.from_response(fixture)),
    )
  let #(edited, _) =
    user_managed.update(initial, user_message.UsernameChanged("changed-user"))
  let #(reset, _) = user_managed.update(edited, user_message.ResetClicked)
  let assert loadable.Loaded(reset_editor) = reset.user
  assert reset_editor.draft == reset_editor.saved

  let #(edited, _) =
    user_managed.update(reset, user_message.UsernameChanged("changed-user"))
  let #(saving, save_command) =
    user_managed.update(edited, user_message.SaveClicked)
  let assert command.Users(users.UpdateUser(request, complete)) = save_command
  assert request.username == "changed-user"

  let #(failed, _) =
    user_managed.update(saving, complete(api_failure("User rejected.")))
  let assert loadable.Loaded(failed_editor) = failed.user
  let assert mutation.SaveError(_) = failed_editor.state

  let #(retrying, retry_command) =
    user_managed.update(failed, user_message.SaveClicked)
  let assert command.Users(users.UpdateUser(_, retry)) = retry_command
  let saved_fixture = user_fixture("changed-user")
  let #(saved, _) =
    user_managed.update(
      retrying,
      retry(response.Success(user_dto.UpdateUserResponse(saved_fixture))),
    )
  let assert loadable.Loaded(saved_editor) = saved.user
  assert saved_editor.state == mutation.Idle
  assert saved_editor.draft == saved_editor.saved
  assert saved_editor.saved.username == "changed-user"
}

pub fn user_detail_links_to_snippets_filtered_by_persisted_username_test() {
  let fixture = user_fixture("fixture-user")
  let #(base, _) = user_managed.init(fixture.id)
  let model =
    user_detail_model.Model(
      ..base,
      user: loadable.Loaded(user_policy.from_response(fixture)),
    )

  let rendered =
    user_view.view(model, timestamp.from_unix_seconds(0))
    |> element.to_document_string

  assert string.contains(
    rendered,
    "href=\"/admin/snippets?username=fixture-user\">Snippets</a>",
  )
}

fn user_fixture(username: String) -> user_dto.UserDetailResponse {
  let now = timestamp.from_unix_seconds(0)
  user_dto.UserDetailResponse(
    id: user_id(),
    account_id: account_id(),
    email: email_address_model.EmailAddress("fixture@example.com"),
    username: username,
    role: user_model.RegularUser,
    account_state: account_model.Active,
    account_state_reason: option.None,
    account_tier: account_model.FreeTier,
    delete_job_id: option.None,
    delete_scheduled_at: option.None,
    last_login_at: now,
    created_at: now,
    updated_at: now,
  )
}

fn user_id() -> uuid.Uuid {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000091")
  id
}

fn account_id() -> uuid.Uuid {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000092")
  id
}

fn api_failure(message: String) -> response.Response(value) {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000099")
  response.ApiFailure(response.Error("fixture", message, id))
}
