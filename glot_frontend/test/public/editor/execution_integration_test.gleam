import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/run
import glot_frontend/api/response
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/message
import glot_frontend/public/editor/view
import lustre/element
import rsvp
import support/editor_fixture
import support/editor_scenario

pub fn runtime_failure_result_is_rendered_as_run_failure_test() {
  let scenario =
    running_scenario()
    |> editor_scenario.respond_to_run(editor_fixture.failed_run(
      "Compilation failed on line 1.",
    ))
  let editor = editor_scenario.editor(scenario)
  let assert execution_operation.Completed(Error(failure)) =
    execution_operation.state(editor.operations.execution)
  assert failure.message == "Compilation failed on line 1."
  let rendered = render(scenario)
  assert string.contains(rendered, "RUN FAILED")
  assert string.contains(rendered, "Compilation failed on line 1.")
}

pub fn stdout_only_result_renders_stdout_panel_test() {
  assert_streams(
    editor_fixture.successful_run(stdout: "stdout value", stderr: "", error: ""),
    present: "editor-shell__result-header--stdout",
    absent: [
      "editor-shell__result-header--stderr",
      "editor-shell__result-header--error",
    ],
  )
}

pub fn stderr_only_result_renders_stderr_panel_test() {
  assert_streams(
    editor_fixture.successful_run(stdout: "", stderr: "stderr value", error: ""),
    present: "editor-shell__result-header--stderr",
    absent: [
      "editor-shell__result-header--stdout",
      "editor-shell__result-header--error",
    ],
  )
}

pub fn runtime_error_only_result_renders_error_panel_test() {
  assert_streams(
    editor_fixture.successful_run(stdout: "", stderr: "", error: "error value"),
    present: "editor-shell__result-header--error",
    absent: [
      "editor-shell__result-header--stdout",
      "editor-shell__result-header--stderr",
    ],
  )
}

pub fn combined_result_preserves_all_streams_and_semantics_test() {
  let scenario =
    running_scenario()
    |> editor_scenario.respond_to_run(editor_fixture.successful_run(
      stdout: "standard output",
      stderr: "standard error",
      error: "runtime error",
    ))
  let rendered = render(scenario)
  assert string.contains(rendered, "editor-shell__result-header--stdout")
  assert string.contains(rendered, "editor-shell__result-header--stderr")
  assert string.contains(rendered, "editor-shell__result-header--error")
  assert string.contains(rendered, "standard output")
  assert string.contains(rendered, "standard error")
  assert string.contains(rendered, "runtime error")
}

pub fn http_run_failure_is_visible_and_leaves_no_pending_work_test() {
  let scenario =
    running_scenario()
    |> editor_scenario.respond_to_run(response.HttpFailure(rsvp.BadBody))
  let editor = editor_scenario.editor(scenario)
  let assert execution_operation.RequestError(message) =
    execution_operation.state(editor.operations.execution)
  assert string.contains(message, "Could not complete")
  assert string.contains(render(scenario), "RUN FAILED")
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn running_state_disables_run_button_and_renders_progress_test() {
  let scenario = running_scenario()
  let editor = editor_scenario.editor(scenario)
  assert execution_operation.state(editor.operations.execution)
    == execution_operation.Running
  let rendered = render(scenario)
  assert string.contains(rendered, "disabled type=\"button\">Running...")
  assert string.contains(rendered, "Running snippet...")
}

pub fn run_request_uses_the_latest_editor_revision_content_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "revision one",
      1,
    ))
    |> editor_scenario.dispatch_execution(message.SourceCodeChanged(
      "revision two",
      2,
    ))
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  let assert [latest_file] = request.payload.files
  assert latest_file.content == "revision two"
  let editor = editor_scenario.editor(scenario)
  assert editor.workspace.editor_revision == 2
}

pub fn stale_run_response_cannot_overwrite_a_newer_result_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
    |> editor_scenario.respond_to_run_at(
      1,
      editor_fixture.successful_run(stdout: "new result", stderr: "", error: ""),
    )
    |> editor_scenario.respond_to_run_at(
      0,
      editor_fixture.successful_run(
        stdout: "stale result",
        stderr: "",
        error: "",
      ),
    )
  let editor = editor_scenario.editor(scenario)
  let assert execution_operation.Completed(Ok(result)) =
    execution_operation.state(editor.operations.execution)
  assert result.stdout == "new result"
  assert string.contains(render(scenario), "new result")
  assert !string.contains(render(scenario), "stale result")
}

fn assert_streams(
  fixture: response.Response(run.RunResult),
  present present: String,
  absent absent: List(String),
) {
  let scenario = running_scenario() |> editor_scenario.respond_to_run(fixture)
  let rendered = render(scenario)
  assert string.contains(rendered, present)
  absent
  |> list.each(fn(class_name) {
    assert !string.contains(rendered, class_name)
  })
}

fn running_scenario() {
  new_scenario() |> editor_scenario.dispatch_execution(message.RunSubmitted)
}

fn new_scenario() {
  editor_scenario.new_editor(language.JavaScript)
  |> editor_scenario.start(option.Some(editor_fixture.owner_id()))
}

fn render(scenario: editor_scenario.Scenario) -> String {
  view.view(
    editor_scenario.model(scenario),
    option.Some(editor_fixture.owner_id()),
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}
