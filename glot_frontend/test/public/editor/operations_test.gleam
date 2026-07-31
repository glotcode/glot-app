import gleam/option
import glot_core/run
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/save_operation

pub fn operation_starts_atomically_select_their_console_test() {
  let initial = operations.initial()
  assert operations.console_owner(initial) == operations.ExecutionConsole

  let #(saving, _) = operations.begin_save(initial)
  assert operations.console_owner(saving) == operations.SaveConsole
  assert operations.save_state(saving) == save_operation.Saving

  let #(running, _) = operations.begin_execution(saving)
  assert operations.console_owner(running) == operations.ExecutionConsole
  assert operations.execution_state(running) == execution_operation.Running
  assert operations.save_state(running) == save_operation.Saving
}

pub fn aggregate_rejects_stale_execution_and_save_completions_test() {
  let #(first_run, first_run_generation) =
    operations.initial() |> operations.begin_execution
  let #(latest_run, latest_run_generation) =
    operations.begin_execution(first_run)
  let run_result = Ok(run.SuccessfulRun(1, "latest", "", ""))

  assert operations.complete_execution(
      latest_run,
      first_run_generation,
      run_result,
    )
    == option.None
  let assert option.Some(_) =
    operations.complete_execution(latest_run, latest_run_generation, run_result)

  let #(first_save, first_save_generation) =
    operations.initial() |> operations.begin_save
  let #(latest_save, latest_save_generation) = operations.begin_save(first_save)

  assert operations.succeed_save(latest_save, first_save_generation, "stale")
    == option.None
  let assert option.Some(_) =
    operations.succeed_save(latest_save, latest_save_generation, "latest")
}

pub fn valid_late_completion_preserves_newer_console_owner_test() {
  let #(saving, save_generation) = operations.initial() |> operations.begin_save
  let #(running_after_save, _) = operations.begin_execution(saving)
  let assert option.Some(save_completed) =
    operations.succeed_save(running_after_save, save_generation, "saved")
  assert operations.console_owner(save_completed) == operations.ExecutionConsole

  let #(running, run_generation) =
    operations.initial() |> operations.begin_execution
  let #(saving_after_run, _) = operations.begin_save(running)
  let run_result = Ok(run.SuccessfulRun(1, "output", "", ""))
  let assert option.Some(run_completed) =
    operations.complete_execution(saving_after_run, run_generation, run_result)
  assert operations.console_owner(run_completed) == operations.SaveConsole
}
