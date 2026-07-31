import gleam/option
import glot_core/run
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/save_operation

pub fn execution_operation_owns_generation_and_run_state_test() {
  let initial = execution_operation.initial()
  let #(first, first_generation) = execution_operation.begin(initial)
  let #(second, second_generation) = execution_operation.begin(first)

  assert execution_operation.state(first) == execution_operation.Running
  assert execution_operation.is_running(first)
  assert !execution_operation.is_current(second, first_generation)
  assert execution_operation.is_current(second, second_generation)

  let result = Ok(run.SuccessfulRun(1, "output", "", ""))
  let completed = execution_operation.complete(second, result)
  assert execution_operation.state(completed)
    == execution_operation.Completed(result)
}

pub fn execution_operation_owns_version_and_failure_state_test() {
  let initial = execution_operation.initial()
  assert execution_operation.version_info(initial) == option.None

  let unchanged = execution_operation.record_version_info(initial, "")
  assert execution_operation.version_info(unchanged) == option.None

  let versioned = execution_operation.record_version_info(initial, "v22")
  assert execution_operation.version_info(versioned) == option.Some("v22")

  let failed = execution_operation.fail(versioned, "Request failed.")
  assert execution_operation.state(failed)
    == execution_operation.RequestError("Request failed.")
}

pub fn save_operation_owns_generation_and_save_state_test() {
  let initial = save_operation.initial()
  let #(first, first_generation) = save_operation.begin(initial)
  let #(second, second_generation) = save_operation.begin(first)

  assert save_operation.state(first) == save_operation.Saving
  assert save_operation.is_saving(first)
  assert !save_operation.is_current(second, first_generation)
  assert save_operation.is_current(second, second_generation)

  let saved = save_operation.succeed(second, "saved-slug")
  assert save_operation.state(saved) == save_operation.Saved("saved-slug")

  let failed = save_operation.fail(second, "Save failed.")
  assert save_operation.state(failed)
    == save_operation.SaveError("Save failed.")
}

pub fn resetting_save_feedback_preserves_request_identity_test() {
  let #(saving, generation) = save_operation.initial() |> save_operation.begin
  let reset = save_operation.reset_feedback(saving)

  assert save_operation.state(reset) == save_operation.SaveIdle
  assert save_operation.is_current(reset, generation)
}
