import gleam/option
import glot_core/admin/rate_limit_config_dto
import glot_core/loadable
import glot_core/public_action
import glot_frontend/admin/command
import glot_frontend/admin/effect/config
import glot_frontend/admin/rate_limits/managed as rate_limits_managed
import glot_frontend/admin/rate_limits/message as rate_limits_message
import glot_frontend/admin/rate_limits/model as rate_limits_model
import glot_frontend/admin/rate_limits/policy as rate_limits_policy
import glot_frontend/api/response
import glot_frontend/request_generation
import glot_frontend/ui/mutation
import youid/uuid

pub fn rate_limit_mutation_covers_cancel_failure_retry_and_success_test() {
  let initial =
    rate_limits_model.Model(
      policies: loadable.Loaded([rate_limit_editor()]),
      active_editor: option.None,
      load_generation: request_generation.initial(),
    )
  let #(editing, open_command) =
    rate_limits_managed.update(
      initial,
      rate_limits_message.EditClicked(public_action.RunAction),
    )
  assert open_command == command.OpenDialog("admin-rate-limits-edit-dialog")
  let #(cancelled, cancel_command) =
    rate_limits_managed.update(editing, rate_limits_message.CancelClicked)
  assert cancel_command == command.CloseDialog("admin-rate-limits-edit-dialog")
  assert cancelled.active_editor == option.None

  let #(editing, _) =
    rate_limits_managed.update(
      cancelled,
      rate_limits_message.EditClicked(public_action.RunAction),
    )
  let #(saving, save_command) =
    rate_limits_managed.update(
      editing,
      rate_limits_message.SaveClicked(public_action.RunAction),
    )
  let assert command.Config(config.UpsertRateLimit(request, complete)) =
    save_command
  assert active_rate_limit(saving).state == mutation.Saving

  let #(failed, _) =
    rate_limits_managed.update(
      saving,
      complete(api_failure("Rate limit rejected.")),
    )
  let assert mutation.SaveError(_) = active_rate_limit(failed).state

  let #(retrying, retry_command) =
    rate_limits_managed.update(
      failed,
      rate_limits_message.SaveClicked(public_action.RunAction),
    )
  let assert command.Config(config.UpsertRateLimit(_, retry)) = retry_command
  let response_fixture =
    rate_limit_config_dto.RateLimitPolicyResponse(
      action: public_action.RunAction,
      rules: request.rules,
    )
  let #(saved, close_command) =
    rate_limits_managed.update(
      retrying,
      retry(response.Success(response_fixture)),
    )
  assert close_command == command.CloseDialog("admin-rate-limits-edit-dialog")
  assert saved.active_editor == option.None
  assert active_rate_limit(saved).state == mutation.Saved
}

fn rate_limit_editor() -> rate_limits_model.PolicyEditor {
  let limits =
    rate_limits_model.LimitFields(second: "5", minute: "", hour: "", day: "")
  let empty = rate_limits_model.LimitFields("", "", "", "")
  let tabs =
    rate_limits_model.PolicyTabs(
      anonymous: limits,
      free: empty,
      free_plus: empty,
    )
  rate_limits_model.PolicyEditor(
    action: public_action.RunAction,
    saved_tabs: tabs,
    draft_tabs: tabs,
    state: mutation.Idle,
    save_generation: request_generation.initial(),
  )
}

fn active_rate_limit(
  model: rate_limits_model.Model,
) -> rate_limits_model.PolicyEditor {
  let assert option.Some(editor) =
    rate_limits_policy.find(
      rate_limits_policy.loaded(model),
      public_action.RunAction,
    )
  editor
}

fn api_failure(message: String) -> response.Response(value) {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000099")
  response.ApiFailure(response.Error("fixture", message, id))
}
