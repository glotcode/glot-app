import gleam/list
import gleam/option
import gleam/string
import gleeunit
import glot_core/run
import glot_frontend/public/editor/console_view
import glot_frontend/public/editor/operations
import lustre/element

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn idle_console_is_empty_until_version_information_arrives_test() {
  let empty = operations.initial() |> render
  assert !string.contains(empty, "editor-shell__console-section")
  assert !string.contains(empty, "editor-shell__result-panel")

  let versioned =
    operations.initial()
    |> operations.record_version_info("Node.js v22")
    |> render
  assert string.contains(versioned, "Node.js v22\nREADY.")
}

pub fn execution_progress_and_request_failure_render_feedback_test() {
  let #(running, generation) =
    operations.initial() |> operations.begin_execution
  assert string.contains(render(running), "Running snippet...")

  let assert option.Some(failed) =
    operations.fail_execution(running, generation, "Network unavailable.")
  let rendered = render(failed)
  assert string.contains(rendered, "RUN FAILED")
  assert string.contains(rendered, "Network unavailable.")
}

pub fn runtime_failure_renders_run_failure_feedback_test() {
  let completed =
    complete_execution(Error(run.FailedRun("Compilation failed.")))
  let rendered = render(completed)

  assert string.contains(rendered, "RUN FAILED")
  assert string.contains(rendered, "Compilation failed.")
}

pub fn successful_run_without_output_returns_to_ready_test() {
  let completed =
    complete_execution(Ok(run.SuccessfulRun(1_000_000, "", "", "")))
  let rendered = render(completed)

  assert string.contains(rendered, "READY.")
  assert !string.contains(rendered, "editor-shell__result-panel")
}

pub fn each_output_stream_renders_its_own_semantic_panel_test() {
  assert_only_stream("stdout", "standard output", "", "")
  assert_only_stream("stderr", "", "standard error", "")
  assert_only_stream("error", "", "", "runtime error")
}

pub fn combined_output_preserves_order_semantics_and_one_duration_test() {
  let rendered =
    complete_execution(
      Ok(run.SuccessfulRun(
        duration: 1_000_000,
        stdout: "standard output",
        stderr: "standard error",
        error: "runtime error",
      )),
    )
    |> render

  assert string.contains(rendered, "editor-shell__result-header--stdout")
  assert string.contains(rendered, "editor-shell__result-header--stderr")
  assert string.contains(rendered, "editor-shell__result-header--error")
  assert string.contains(rendered, "standard output")
  assert string.contains(rendered, "standard error")
  assert string.contains(rendered, "runtime error")
  assert string.contains(rendered, "1.00ms")
  assert rendered |> string.split("1.00ms") |> list.length == 2
}

pub fn save_progress_failure_and_success_render_feedback_test() {
  let #(saving, generation) = operations.initial() |> operations.begin_save
  assert string.contains(render(saving), "Saving snippet...")

  let assert option.Some(failed) =
    operations.fail_save(saving, generation, "Storage unavailable.")
  let failed_rendered = render(failed)
  assert string.contains(failed_rendered, "SAVE FAILED")
  assert string.contains(failed_rendered, "Storage unavailable.")

  let assert option.Some(saved) =
    operations.succeed_save(saving, generation, "saved-slug")
  assert string.contains(render(saved), ">Saved</pre>")
}

pub fn latest_operation_owner_selects_the_visible_console_feedback_test() {
  let completed =
    complete_execution(Ok(run.SuccessfulRun(1_000_000, "run output", "", "")))
  let #(saving, _) = operations.begin_save(completed)
  let rendered = render(saving)

  assert string.contains(rendered, "Saving snippet...")
  assert !string.contains(rendered, "run output")
}

fn assert_only_stream(
  label: String,
  stdout: String,
  stderr: String,
  error: String,
) {
  let rendered =
    complete_execution(Ok(run.SuccessfulRun(1_000_000, stdout, stderr, error)))
    |> render

  assert string.contains(rendered, "editor-shell__result-header--" <> label)
  ["stdout", "stderr", "error"]
  |> list.filter(fn(other) { other != label })
  |> list.each(fn(other) {
    assert !string.contains(rendered, "editor-shell__result-header--" <> other)
  })
  assert string.contains(rendered, "1.00ms")
}

fn complete_execution(result: run.RunResult) -> operations.Operations {
  let #(running, generation) =
    operations.initial() |> operations.begin_execution
  let assert option.Some(completed) =
    operations.complete_execution(running, generation, result)
  completed
}

fn render(editor_operations: operations.Operations) -> String {
  console_view.view(editor_operations) |> element.to_document_string
}
