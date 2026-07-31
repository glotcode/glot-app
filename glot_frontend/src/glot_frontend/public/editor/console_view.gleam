import gleam/list
import gleam/option
import gleam/string
import glot_core/run
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/operations.{
  type ConsoleOwner, ExecutionConsole, SaveConsole,
}
import glot_frontend/public/editor/save_operation
import glot_frontend/ui/duration_label
import glot_web/page/editor_layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(editor_operations: operations.Operations) -> Element(msg) {
  let owner = operations.console_owner(editor_operations)
  let run_state = operations.execution_state(editor_operations)
  let save_state = operations.save_state(editor_operations)
  editor_layout.console_shell(
    header: header(owner, run_state),
    body: content(
      owner,
      operations.version_info(editor_operations),
      run_state,
      save_state,
    ),
  )
}

fn header(
  owner: ConsoleOwner,
  run_state: execution_operation.State,
) -> Element(msg) {
  case owner, run_state {
    ExecutionConsole, execution_operation.Completed(Ok(_)) -> html.div([], [])
    _, _ ->
      html.div([attribute.class("editor-shell__console-header")], [
        html.text("INFO"),
      ])
  }
}

fn content(
  owner: ConsoleOwner,
  version_info: option.Option(String),
  run_state: execution_operation.State,
  save_state: save_operation.State,
) -> Element(msg) {
  case owner {
    ExecutionConsole -> run_content(version_info, run_state)
    SaveConsole -> save_content(save_state)
  }
}

fn save_content(save_state: save_operation.State) -> Element(msg) {
  case save_state {
    save_operation.SaveError(message) -> block("SAVE FAILED", message)
    save_operation.Saving -> block("", "Saving snippet...")
    save_operation.Saved(_) -> block("", "Saved")
    save_operation.SaveIdle -> html.div([], [])
  }
}

fn run_content(
  version_info: option.Option(String),
  run_state: execution_operation.State,
) -> Element(msg) {
  case run_state {
    execution_operation.Idle ->
      case version_info {
        option.Some(stdout) -> block("", stdout <> "\nREADY.")
        option.None -> html.div([], [])
      }
    execution_operation.Running -> block("", "Running snippet...")
    execution_operation.RequestError(message) -> block("RUN FAILED", message)
    execution_operation.Completed(result) ->
      case result {
        Ok(success) -> successful(success)
        Error(failure) -> block("RUN FAILED", failure.message)
      }
  }
}

fn successful(success: run.SuccessfulRun) -> Element(msg) {
  let run.SuccessfulRun(duration:, stdout:, stderr:, error:) = success
  [
    ResultStream("stdout", stdout),
    ResultStream("stderr", stderr),
    ResultStream("error", error),
  ]
  |> list.filter(fn(output) { output.content != "" })
  |> output_panels(duration)
}

type ResultStream {
  ResultStream(label: String, content: String)
}

fn output_panels(outputs: List(ResultStream), duration: Int) -> Element(msg) {
  case outputs {
    [] -> block("", "READY.")
    [first, ..remaining] ->
      html.div([], [
        result_panel(first.label, first.content, option.Some(duration)),
        ..list.map(remaining, fn(output) {
          result_panel(output.label, output.content, option.None)
        })
      ])
  }
}

fn block(label: String, content: String) -> Element(msg) {
  let label_view = case label == "" {
    True -> html.div([], [])
    False ->
      html.div([attribute.class("editor-shell__console-label")], [
        html.text(label),
      ])
  }
  html.div([attribute.class("editor-shell__console-section")], [
    label_view,
    html.pre([attribute.class("editor-shell__console-pre")], [
      html.text(content),
    ]),
  ])
}

fn result_panel(
  label: String,
  content: String,
  duration: option.Option(Int),
) -> Element(msg) {
  html.div([attribute.class("editor-shell__result-panel")], [
    html.div([attribute.class(header_class(label))], [
      html.span([attribute.class("editor-shell__result-title")], [
        html.text(string.uppercase(label)),
      ]),
      duration_view(duration),
    ]),
    html.div([attribute.class("editor-shell__result-body")], [
      html.pre([attribute.class("editor-shell__result-pre")], [
        html.text(content),
      ]),
    ]),
  ])
}

fn duration_view(duration: option.Option(Int)) -> Element(msg) {
  case duration {
    option.Some(value) ->
      html.span([attribute.class("editor-shell__result-duration")], [
        html.text(duration_label.duration_in_ms_label(value)),
      ])
    option.None -> html.div([], [])
  }
}

fn header_class(label: String) -> String {
  case label {
    "stdout" ->
      "editor-shell__result-header editor-shell__result-header--stdout"
    "stderr" ->
      "editor-shell__result-header editor-shell__result-header--stderr"
    "error" -> "editor-shell__result-header editor-shell__result-header--error"
    _ -> "editor-shell__result-header"
  }
}
