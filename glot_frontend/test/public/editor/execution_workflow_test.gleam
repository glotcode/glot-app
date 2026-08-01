import gleam/option
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/execution_workflow
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import support/editor_fixture

pub fn run_projects_one_complete_editor_snapshot_into_the_request_test() {
  let custom = language.RunInstructions(["npm build"], "node dist.js")
  let base = ready.new(language.JavaScript, settings.defaults())
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        files: [
          snippet_model.File("main.js", "main"),
          snippet_model.File("helper.js", "helper"),
        ],
        stdin: option.Some("input"),
        run_instructions_override: option.Some(custom),
      ),
    )
  let #(running, next_command) = execution_workflow.run_snippet(editor)

  assert operations.execution_state(running.operations)
    == execution_operation.Running
  assert operations.console_owner(running.operations)
    == operations.ExecutionConsole
  let assert command.Batch([
    command.RunCode(request, complete),
    command.Schedule(
      3000,
      message.RunCancellationDelayElapsed(delay_generation),
    ),
  ]) = next_command
  assert request.image == language.container_image(language.JavaScript)
  assert request.payload.run_instructions == custom
  assert request.payload.files == editor.snippet.files
  assert request.payload.stdin == option.Some("input")
  assert operations.offer_execution_cancellation(
      running.operations,
      delay_generation,
    )
    != option.None
  assert_callback_generation_is_current(running, complete)
}

pub fn run_uses_language_defaults_when_no_override_exists_test() {
  let base = ready.new(language.JavaScript, settings.defaults())
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        files: [snippet_model.File("app.js", "source")],
        stdin: option.None,
        run_instructions_override: option.None,
      ),
    )
  let #(_, next_command) = execution_workflow.run_snippet(editor)
  let assert command.Batch([
    command.RunCode(request, _),
    command.Schedule(3000, _),
  ]) = next_command

  assert request.payload.run_instructions.run_command == "node app.js"
  assert request.payload.stdin == option.None
}

fn assert_callback_generation_is_current(
  editor: model.Editor,
  complete: fn(response.Response(run.RunResult)) -> message.ExecutionMsg,
) -> Nil {
  let fixture =
    editor_fixture.successful_run(stdout: "output", stderr: "", error: "")
  let assert message.RunFinished(generation, response.Success(result)) =
    complete(fixture)
  let assert option.Some(_) =
    operations.complete_execution(editor.operations, generation, result)
  Nil
}
