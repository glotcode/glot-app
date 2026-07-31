import gleam/option
import gleam/string
import glot_core/run
import glot_frontend/ui/duration_label
import glot_web/page/editor_layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type RunState {
  Idle
  Running
  Completed(run.RunResult)
  RequestError(String)
}

pub type SaveState {
  SaveIdle
  Saving
  Saved(slug: String)
  SaveError(String)
}

pub fn run_button_text(run_state: RunState) -> String {
  case run_state {
    Running -> "Running..."
    _ -> "Run"
  }
}

pub fn save_button_text(save_state: SaveState) -> String {
  case save_state {
    Saving -> "Saving..."
    _ -> "Save"
  }
}

pub fn view(
  version_info: option.Option(String),
  run_state: RunState,
  save_state: SaveState,
) -> Element(msg) {
  editor_layout.console_shell(
    header: header(version_info, run_state, save_state),
    body: content(version_info, run_state, save_state),
  )
}

fn header(
  version_info: option.Option(String),
  run_state: RunState,
  save_state: SaveState,
) -> Element(msg) {
  case save_state, run_state, version_info {
    SaveIdle, Completed(Ok(_)), _ -> html.div([], [])
    _, _, _ ->
      html.div([attribute.class("editor-shell__console-header")], [
        html.text("INFO"),
      ])
  }
}

fn content(
  version_info: option.Option(String),
  run_state: RunState,
  save_state: SaveState,
) -> Element(msg) {
  case save_state {
    SaveError(message) -> block("SAVE FAILED", message)
    Saving -> block("", "Saving snippet...")
    Saved(_) -> block("", "Saved")
    SaveIdle -> run_content(version_info, run_state)
  }
}

fn run_content(
  version_info: option.Option(String),
  run_state: RunState,
) -> Element(msg) {
  case run_state {
    Idle ->
      case version_info {
        option.Some(stdout) -> block("", stdout <> "\nREADY.")
        option.None -> html.div([], [])
      }
    Running -> block("", "Running snippet...")
    RequestError(message) -> block("RUN FAILED", message)
    Completed(result) ->
      case result {
        Ok(success) -> successful(success)
        Error(failure) -> block("RUN FAILED", failure.message)
      }
  }
}

fn successful(success: run.SuccessfulRun) -> Element(msg) {
  let run.SuccessfulRun(duration:, stdout:, stderr:, error:) = success
  case stdout != "" {
    True ->
      html.div([], [
        result_panel("stdout", stdout, option.Some(duration)),
        optional_result_panel("stderr", stderr),
        optional_result_panel("error", error),
      ])
    False ->
      case stderr != "" {
        True ->
          html.div([], [
            result_panel("stderr", stderr, option.Some(duration)),
            optional_result_panel("error", error),
          ])
        False ->
          case error != "" {
            True -> result_panel("error", error, option.Some(duration))
            False -> block("", "READY.")
          }
      }
  }
}

fn optional_result_panel(label: String, content: String) -> Element(msg) {
  case content == "" {
    True -> html.div([], [])
    False -> result_panel(label, content, option.None)
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
