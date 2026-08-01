import glot_core/language
import glot_core/run
import glot_frontend/public/editor/command
import glot_frontend/public/editor/message.{
  type ExecutionMsg, RunCancellationDelayElapsed, RunFinished,
}
import glot_frontend/public/editor/model.{type Editor, Editor}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/run_instructions

const cancellation_delay_ms = 3000

/// Start a run from one coherent editor snapshot. The returned generation and
/// request are created together so later completions can be correlated with
/// the exact operation that emitted the request.
pub fn run_snippet(editor: Editor) -> #(Editor, command.Command(ExecutionMsg)) {
  let #(next_operations, generation) =
    operations.begin_execution(editor.operations)
  let request =
    run.RunRequest(
      image: language.container_image(editor.snippet.language),
      payload: run.RunRequestPayload(
        run_instructions: run_instructions.effective_run_instructions(editor),
        files: editor.snippet.files,
        stdin: editor.snippet.stdin,
      ),
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
