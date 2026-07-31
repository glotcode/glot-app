import gleam/option
import glot_core/language
import glot_frontend/public/editor/message
import glot_frontend/public/editor/settings
import support/editor_fixture
import support/editor_scenario

pub fn custom_run_instructions_and_keyboard_settings_drive_execution_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(message.KeyboardBindingsDraftSelected(
      settings.VimBindings,
    ))
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsBuildCommandsDraftChanged(
        " npm install \n\n npm run build ",
      ),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsRunCommandDraftChanged(" node dist/main.js "),
    )
    |> editor_scenario.dispatch_settings(message.SettingsSubmitted)
  assert editor_scenario.observed_settings_save(scenario)
  assert editor_scenario.observed_draft_save(scenario)

  let scenario =
    editor_scenario.dispatch_execution(scenario, message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)
  assert request.payload.run_instructions
    == language.RunInstructions(
      ["npm install", "npm run build"],
      "node dist/main.js",
    )
}

pub fn switching_custom_instructions_back_to_default_drives_execution_test() {
  let scenario =
    new_scenario()
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsRunCommandDraftChanged("custom"),
    )
    |> editor_scenario.dispatch_settings(message.SettingsSubmitted)
    |> editor_scenario.dispatch_settings(message.SettingsClicked)
    |> editor_scenario.dispatch_settings(
      message.RunInstructionsModeDraftChanged("default"),
    )
    |> editor_scenario.dispatch_settings(message.SettingsSubmitted)
    |> editor_scenario.dispatch_execution(message.RunSubmitted)
  let assert [editor_scenario.RunCode(request, _)] =
    editor_scenario.pending(scenario)

  assert request.payload.run_instructions.run_command == "node main.js"
}

fn new_scenario() -> editor_scenario.Scenario {
  editor_scenario.start_new_editor(
    language.JavaScript,
    option.Some(editor_fixture.owner_id()),
  )
}
