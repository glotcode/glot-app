import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type SettingsMsg, KeyboardBindingsDraftSelected,
  RunInstructionsBuildCommandsDraftChanged, RunInstructionsModeDraftChanged,
  RunInstructionsRunCommandDraftChanged, SettingsCancelled, SettingsClicked,
  SettingsDialogClosed, SettingsSubmitted,
}
import glot_frontend/public/editor/model.{
  type Editor, Editor, RunInstructionsDraft, SettingsDraft, Snippet,
}
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/settings as editor_settings

pub fn update(
  model: Editor,
  msg: SettingsMsg,
) -> #(Editor, command.Command(SettingsMsg)) {
  case msg {
    SettingsClicked -> #(
      Editor(
        ..model,
        settings_draft: SettingsDraft(
          editor_settings: model.editor_settings,
          run_instructions_mode: run_instructions.run_instructions_mode(model),
          run_instructions: run_instructions.run_instructions_to_draft(
            run_instructions.effective_run_instructions(model),
          ),
        ),
      ),
      command.OpenDialog(ids.settings_dialog),
    )

    KeyboardBindingsDraftSelected(bindings) -> #(
      Editor(
        ..model,
        settings_draft: SettingsDraft(
          ..model.settings_draft,
          editor_settings: editor_settings.EditorSettings(
            keyboard_bindings: bindings,
          ),
        ),
      ),
      command.none(),
    )

    RunInstructionsModeDraftChanged(value) -> #(
      Editor(
        ..model,
        settings_draft: SettingsDraft(
          ..model.settings_draft,
          run_instructions_mode: run_instructions.run_instructions_mode_from_string(
            value,
          ),
        ),
      ),
      command.none(),
    )

    RunInstructionsBuildCommandsDraftChanged(build_commands_text) -> {
      #(
        Editor(
          ..model,
          settings_draft: SettingsDraft(
            ..model.settings_draft,
            run_instructions: RunInstructionsDraft(
              build_commands_text: build_commands_text,
              run_command: model.settings_draft.run_instructions.run_command,
            ),
          ),
        ),
        command.none(),
      )
    }

    RunInstructionsRunCommandDraftChanged(run_command) -> {
      #(
        Editor(
          ..model,
          settings_draft: SettingsDraft(
            ..model.settings_draft,
            run_instructions: RunInstructionsDraft(
              build_commands_text: model.settings_draft.run_instructions.build_commands_text,
              run_command: run_command,
            ),
          ),
        ),
        command.none(),
      )
    }

    SettingsCancelled -> #(
      Editor(
        ..model,
        settings_draft: SettingsDraft(
          editor_settings: model.editor_settings,
          run_instructions_mode: run_instructions.run_instructions_mode(model),
          run_instructions: run_instructions.run_instructions_to_draft(
            run_instructions.effective_run_instructions(model),
          ),
        ),
      ),
      command.CloseDialog(ids.settings_dialog),
    )

    SettingsSubmitted -> {
      let next_model =
        Editor(
          ..model,
          editor_settings: model.settings_draft.editor_settings,
          snippet: Snippet(
            ..model.snippet,
            run_instructions_override: run_instructions.run_instructions_override_from_draft(
              model,
            ),
          ),
        )

      #(
        next_model,
        command.batch([
          command.CloseDialog(ids.settings_dialog),
          command.SaveSettings(model.settings_draft.editor_settings),
          command.SaveDraft(draft_projection.write(next_model)),
        ]),
      )
    }

    SettingsDialogClosed -> #(
      Editor(
        ..model,
        settings_draft: SettingsDraft(
          editor_settings: model.editor_settings,
          run_instructions_mode: run_instructions.run_instructions_mode(model),
          run_instructions: run_instructions.run_instructions_to_draft(
            run_instructions.effective_run_instructions(model),
          ),
        ),
      ),
      focus_editor(),
    )
  }
}

fn focus_editor() -> command.Command(msg) {
  command.Focus(ids.editor)
}
