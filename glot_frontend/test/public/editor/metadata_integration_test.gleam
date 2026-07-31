import gleam/option
import gleam/string
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/message
import support/editor_fixture
import support/editor_scenario

pub fn submission_updates_rendering_and_persists_the_draft_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_metadata(message.EditMetadataClicked)
    |> editor_scenario.dispatch_metadata(message.TitleDraftChanged("New title"))
    |> editor_scenario.dispatch_metadata(message.EditMetadataVisibilitySelected(
      snippet_model.Public,
    ))
    |> editor_scenario.dispatch_metadata(message.EditMetadataSubmitted)
  assert editor_scenario.observed_draft_save(scenario)
  assert string.contains(editor_scenario.render(scenario), ">New title</h1>")
}

fn new_scenario() -> editor_scenario.Scenario {
  editor_scenario.start_new_editor(
    language.JavaScript,
    option.Some(editor_fixture.owner_id()),
  )
}
