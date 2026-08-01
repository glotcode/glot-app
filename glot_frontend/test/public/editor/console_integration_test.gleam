import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/public/editor/message
import support/editor_fixture
import support/editor_scenario

pub fn older_save_completion_cannot_hide_newer_run_feedback_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [
    editor_scenario.CreateSnippet(create_request, _),
    editor_scenario.RunCode(_, _),
  ] = editor_scenario.pending(scenario)

  let scenario =
    editor_scenario.respond_to_run_at(
      scenario,
      1,
      editor_fixture.successful_run(
        stdout: "newer run output",
        stderr: "",
        error: "",
      ),
    )
  assert string.contains(editor_scenario.render(scenario), "newer run output")

  let scenario =
    editor_scenario.respond_to_create_at(
      scenario,
      0,
      response.Success(created_from_request("older-save", create_request)),
    )
    |> editor_scenario.deliver_next_scheduled
  let rendered = editor_scenario.render(scenario)
  assert string.contains(rendered, "newer run output")
  assert !string.contains(rendered, "Saved")
  editor_scenario.assert_no_pending_effects(scenario)
}

pub fn older_run_completion_cannot_hide_newer_save_feedback_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
    |> editor_scenario.dispatch_save(message.SaveConfirmed)
  let assert [
    editor_scenario.RunCode(_, _),
    editor_scenario.CreateSnippet(create_request, _),
  ] = editor_scenario.pending(scenario)

  let scenario =
    editor_scenario.respond_to_create_at(
      scenario,
      1,
      response.Success(created_from_request("newer-save", create_request)),
    )
  assert string.contains(editor_scenario.render(scenario), "Saved")

  let scenario =
    editor_scenario.respond_to_run_at(
      scenario,
      0,
      editor_fixture.successful_run(
        stdout: "older run output",
        stderr: "",
        error: "",
      ),
    )
    |> editor_scenario.deliver_next_scheduled
  let rendered = editor_scenario.render(scenario)
  assert string.contains(rendered, "Saved")
  assert !string.contains(rendered, "older run output")
  editor_scenario.assert_no_pending_effects(scenario)
}

fn new_scenario() -> editor_scenario.Scenario {
  editor_scenario.start_new_editor(
    language.JavaScript,
    option.Some(editor_fixture.owner_id()),
  )
}

fn created_from_request(
  slug: String,
  request: snippet_dto.CreateSnippetRequest,
) -> snippet_dto.SnippetResponse {
  editor_fixture.updated(editor_fixture.snippet(slug, ""), request.data)
}
