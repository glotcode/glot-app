import gleam/string
import glot_core/language
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/model
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/settings_dialog_view
import lustre/element

pub fn default_run_instructions_keep_command_fields_disabled_test() {
  let rendered = new_editor() |> render

  assert string.contains(rendered, "aria-label=\"Editor settings\"")
  assert string.contains(rendered, "value=\"default\"")
  assert string.contains(rendered, "disabled")
  assert string.contains(rendered, ">Apply</button>")
}

pub fn custom_draft_renders_editable_commands_and_keyboard_choice_test() {
  let base = new_editor()
  let editor =
    model.Editor(
      ..base,
      settings_draft: model.SettingsDraft(
        settings.EditorSettings(settings.VimBindings),
        model.CustomRunInstructions,
        model.RunInstructionsDraft("npm build\nnpm test", "node dist.js"),
      ),
    )
  let rendered = render(editor)

  assert string.contains(rendered, "value=\"custom\"")
  assert string.contains(rendered, "npm build\nnpm test")
  assert string.contains(rendered, "value=\"node dist.js\"")
  assert string.contains(
    rendered,
    "editor-page__settings-option--selected\" type=\"button\"><span class=\"editor-page__settings-option-title\">Vim",
  )
  assert !string.contains(rendered, "disabled")
}

fn new_editor() -> model.Editor {
  ready.new(language.JavaScript, environment.defaults())
}

fn render(editor: model.Editor) -> String {
  settings_dialog_view.view(editor) |> element.to_document_string
}
