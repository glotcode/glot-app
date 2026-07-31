import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model
import glot_frontend/public/editor/run_instructions
import support/editor_scenario

pub fn draft_conversion_is_trimmed_and_round_trips_test() {
  let instructions =
    language.RunInstructions(
      build_commands: ["npm install", "npm run build"],
      run_command: "node main.js",
    )
  let draft = run_instructions.run_instructions_to_draft(instructions)

  assert draft
    == model.RunInstructionsDraft(
      build_commands_text: "npm install\nnpm run build",
      run_command: "node main.js",
    )
  assert run_instructions.run_instructions_from_draft(
      model.RunInstructionsDraft(
        build_commands_text: " npm install \n\n npm run build ",
        run_command: " node main.js ",
      ),
    )
    == instructions
}

pub fn mode_conversions_have_a_stable_default_test() {
  let custom = language.RunInstructions([], "node custom.js")

  assert run_instructions.run_instructions_mode_from_override(option.None)
    == model.DefaultRunInstructions
  assert run_instructions.run_instructions_mode_from_override(option.Some(
      custom,
    ))
    == model.CustomRunInstructions
  assert run_instructions.run_instructions_mode_from_string("custom")
    == model.CustomRunInstructions
  assert run_instructions.run_instructions_mode_from_string("unknown")
    == model.DefaultRunInstructions
  assert run_instructions.run_instructions_mode_to_string(
      model.DefaultRunInstructions,
    )
    == "default"
  assert run_instructions.run_instructions_mode_to_string(
      model.CustomRunInstructions,
    )
    == "custom"
}

pub fn language_defaults_use_the_conventional_main_file_when_present_test() {
  let instructions =
    run_instructions.default_run_instructions(language.JavaScript, [
      snippet_model.File("helper.js", ""),
      snippet_model.File("main.js", ""),
      snippet_model.File("other.js", ""),
    ])

  assert instructions.run_command == "node main.js"
}

pub fn language_defaults_fall_back_to_the_first_file_test() {
  let instructions =
    run_instructions.default_run_instructions(language.JavaScript, [
      snippet_model.File("app.js", ""),
      snippet_model.File("helper.js", ""),
    ])

  assert instructions.run_command == "node app.js"
}

pub fn effective_and_persisted_instructions_follow_the_selected_mode_test() {
  let assert model.Ready(base) = editor_scenario.new_editor(language.JavaScript)
  let custom = language.RunInstructions(["npm build"], "node dist.js")
  let custom_editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        run_instructions_override: option.Some(custom),
      ),
    )
  assert run_instructions.effective_run_instructions(custom_editor) == custom

  let default_editor =
    model.Editor(
      ..custom_editor,
      settings_draft: model.SettingsDraft(
        ..custom_editor.settings_draft,
        run_instructions_mode: model.DefaultRunInstructions,
      ),
    )
  assert run_instructions.run_instructions_override_from_draft(default_editor)
    == option.None

  let custom_draft_editor =
    model.Editor(
      ..default_editor,
      settings_draft: model.SettingsDraft(
        ..default_editor.settings_draft,
        run_instructions_mode: model.CustomRunInstructions,
        run_instructions: model.RunInstructionsDraft(
          " npm build ",
          " node dist.js ",
        ),
      ),
    )
  assert run_instructions.run_instructions_override_from_draft(
      custom_draft_editor,
    )
    == option.Some(custom)
}
