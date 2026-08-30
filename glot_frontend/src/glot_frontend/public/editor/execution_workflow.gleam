import glot_core/run
import glot_frontend/public/editor/command
import glot_frontend/public/editor/message.{
  type ExecutionMsg, RunCancellationDelayElapsed, RunFinished,
}
import glot_frontend/public/editor/model.{type Editor, Editor}
import glot_frontend/public/editor/operations

const cancellation_delay_ms = 3000

/// Start a run from one coherent editor snapshot. The returned generation and
/// request are created together so later completions can be correlated with
/// the exact operation that emitted the request.
pub fn run_snippet(editor: Editor) -> #(Editor, command.Command(ExecutionMsg)) {
  let #(next_operations, generation) =
    operations.begin_execution(editor.operations)
  let request =
    run.snippet_request(
      editor.snippet.language,
      editor.snippet.run_instructions_override,
      editor.snippet.files,
      editor.snippet.stdin,
    )

  #(
    Editor(..editor, operations: next_operations),
    command.batch([
      command.RunCode(request, fn(result) { RunFinished(generation, result) }),
      command.Schedule(
        cancellation_delay_ms,
        RunCancellationDelayElapsed(generation),
      ),
    ]),
  )
}
