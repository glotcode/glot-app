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

pub fn output_streams_render_distinct_semantic_colors_test() {
  let result =
    Ok(run.SuccessfulRun(
      duration: 1_000_000,
      stdout: "standard output",
      stderr: "standard error",
      error: "runtime error",
    ))
  let #(running, generation) =
    operations.initial() |> operations.begin_execution
  let assert option.Some(completed) =
    operations.complete_execution(running, generation, result)
  let rendered =
    console_view.view(completed)
    |> element.to_document_string

  assert string.contains(rendered, "editor-shell__result-header--stdout")
  assert string.contains(rendered, "editor-shell__result-header--stderr")
  assert string.contains(rendered, "editor-shell__result-header--error")
}
