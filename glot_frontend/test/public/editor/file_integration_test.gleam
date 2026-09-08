import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import support/editor_fixture
import support/editor_scenario

pub fn added_file_renders_and_participates_in_execution_test() {
  let scenario =
    new_scenario()
    |> add_file("helper.js")
    |> editor_scenario.type_source("export const answer = 42")
  assert string.contains(editor_scenario.render(scenario), "helper.js")

  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.files
    == [
      snippet_model.File("main.js", "console.log(\"Hello World!\");"),
      snippet_model.File("helper.js", "export const answer = 42"),
    ]
  assert editor_scenario.observed_draft_save(scenario)
}

pub fn renamed_and_deleted_files_reach_the_execution_request_test() {
  let scenario =
    new_scenario()
    |> add_file("second.js")
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryFilenameChanged(
      "renamed.js",
    ))
    |> editor_scenario.dispatch_file(message.EditEntrySubmitted)
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryDeleted)
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)

  assert request.payload.files
    == [snippet_model.File("main.js", "console.log(\"Hello World!\");")]
  assert editor_scenario.observed_draft_save(scenario)
}

pub fn stdin_edits_reach_execution_and_removal_restores_the_file_document_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_file(message.AddEntryClicked)
    |> editor_scenario.dispatch_file(message.AddEntryKindSelected(
      model.AddStdinEntry,
    ))
    |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
    |> editor_scenario.type_source("fixture input")
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.stdin == option.Some("fixture input")

  let scenario =
    editor_scenario.respond_to_run(
      scenario,
      editor_fixture.successful_run(stdout: "ok", stderr: "", error: ""),
    )
    |> editor_scenario.dispatch_file(message.SelectedTabActionClicked)
    |> editor_scenario.dispatch_file(message.EditEntryDeleted)
  let editor = editor_scenario.editor(scenario)
  assert editor.snippet.stdin == option.None
  assert editor.workspace.selected_tab == model.FileTab(0)
  assert editor_scenario.observed_draft_save(scenario)
}

fn new_scenario() -> editor_scenario.Scenario {
  editor_scenario.start_new_editor(
    language.JavaScript,
    option.Some(editor_fixture.owner_id()),
  )
}

fn add_file(scenario: editor_scenario.Scenario, name: String) {
  scenario
  |> editor_scenario.dispatch_file(message.AddEntryClicked)
  |> editor_scenario.dispatch_file(message.AddEntryFilenameChanged(name))
  |> editor_scenario.dispatch_file(message.AddEntrySubmitted)
}
