import gleam/option
import glot_core/language
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

pub fn duplicate_run_submission_is_ignored_while_running_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [editor_scenario.RunCode(_, _)] = editor_scenario.pending(scenario)
  assert operations.execution_state(editor_scenario.editor(scenario).operations)
    == execution_operation.Running
}

fn new_scenario() {
  editor_scenario.start_new_editor(
    language.JavaScript,
    option.Some(editor_fixture.owner_id()),
  )
}
