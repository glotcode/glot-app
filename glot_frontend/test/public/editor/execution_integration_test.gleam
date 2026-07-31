import gleam/option
import glot_core/language
import glot_core/run
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/message
import glot_frontend/public/editor/operations
import support/editor_fixture
import support/editor_scenario

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
  assert operations.execution_state(editor_scenario.editor(scenario).operations)
    == execution_operation.Completed(
      Ok(run.SuccessfulRun(1_000_000, "new result", "", "")),
    )
}

fn new_scenario() {
  editor_scenario.start_new_editor(
    language.JavaScript,
    option.Some(editor_fixture.owner_id()),
  )
}
