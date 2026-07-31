import gleam/dynamic/decode
import glot_frontend/public/editor/dialog_controls
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type SettingsMsg, RunInstructionsBuildCommandsDraftChanged,
  RunInstructionsModeDraftChanged, RunInstructionsRunCommandDraftChanged,
  SettingsCancelled, SettingsDialogClosed, SettingsSubmitted,
}
import glot_frontend/public/editor/model.{
  type Editor, CustomRunInstructions, DefaultRunInstructions,
}
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/settings as editor_settings
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Editor) -> Element(SettingsMsg) {
  let custom_run_instructions =
    model.settings_draft.run_instructions_mode == CustomRunInstructions

  html.dialog(
    [
      attribute.id(ids.settings_dialog),
      attribute.class("editor-page__dialog"),
      attribute.attribute("aria-label", "Editor settings"),
      event.on("close", decode.success(SettingsDialogClosed)),
    ],
    [
      html.form(
        [
          attribute.class("editor-page__dialog-form"),
          event.on_submit(fn(_) { SettingsSubmitted }),
        ],
        [
          html.h2([attribute.class("editor-page__dialog-label")], [
            html.text("Keyboard bindings"),
          ]),
          html.div(
            [
              attribute.class("editor-page__dialog-panel"),
              attribute.attribute("role", "group"),
              attribute.attribute("aria-label", "Keyboard bindings"),
            ],
            [
              dialog_controls.keyboard_bindings_option(
                "Default",
                "Standard CodeMirror shortcuts.",
                editor_settings.DefaultBindings,
                model.settings_draft.editor_settings.keyboard_bindings,
              ),
              dialog_controls.keyboard_bindings_option(
                "Emacs",
                "Enable Emacs-style editing commands.",
                editor_settings.EmacsBindings,
                model.settings_draft.editor_settings.keyboard_bindings,
              ),
              dialog_controls.keyboard_bindings_option(
                "Vim",
                "Enable modal Vim keybindings.",
                editor_settings.VimBindings,
                model.settings_draft.editor_settings.keyboard_bindings,
              ),
            ],
          ),
          html.div([attribute.class("editor-page__dialog-divider")], []),
          html.div([attribute.class("editor-page__dialog-section")], [
            html.label(
              [
                attribute.for("editor-page-run-instructions-mode"),
                attribute.class("editor-page__dialog-label"),
              ],
              [
                html.text("Run instructions"),
              ],
            ),
            html.div([attribute.class("editor-page__dialog-panel")], [
              html.select(
                [
                  attribute.id("editor-page-run-instructions-mode"),
                  attribute.name("run_instructions_mode"),
                  attribute.class("editor-page__dialog-select"),
                  attribute.value(
                    run_instructions.run_instructions_mode_to_string(
                      model.settings_draft.run_instructions_mode,
                    ),
                  ),
                  event.on_input(RunInstructionsModeDraftChanged),
                ],
                [
                  html.option(
                    [
                      attribute.value("default"),
                      attribute.selected(
                        model.settings_draft.run_instructions_mode
                        == DefaultRunInstructions,
                      ),
                    ],
                    "Default",
                  ),
                  html.option(
                    [
                      attribute.value("custom"),
                      attribute.selected(
                        model.settings_draft.run_instructions_mode
                        == CustomRunInstructions,
                      ),
                    ],
                    "Custom",
                  ),
                ],
              ),
              html.label(
                [
                  attribute.for("editor-page-build-commands-input"),
                  attribute.class("editor-page__dialog-sublabel"),
                ],
                [html.text("Build commands")],
              ),
              html.textarea(
                [
                  attribute.id("editor-page-build-commands-input"),
                  attribute.name("build_commands"),
                  attribute.rows(2),
                  attribute.class(
                    "editor-page__dialog-input editor-page__dialog-input--multiline",
                  ),
                  attribute.disabled(!custom_run_instructions),
                  event.on_input(RunInstructionsBuildCommandsDraftChanged),
                ],
                model.settings_draft.run_instructions.build_commands_text,
              ),
              html.p([attribute.class("editor-page__dialog-helper-text")], [
                html.text(
                  "One build command per line. Leave blank to skip build.",
                ),
              ]),
              html.label(
                [
                  attribute.for("editor-page-run-command-input"),
                  attribute.class("editor-page__dialog-sublabel"),
                ],
                [html.text("Run command")],
              ),
              html.input([
                attribute.id("editor-page-run-command-input"),
                attribute.name("run_command"),
                attribute.type_("text"),
                attribute.value(
                  model.settings_draft.run_instructions.run_command,
                ),
                attribute.class("editor-page__dialog-input"),
                attribute.disabled(!custom_run_instructions),
                event.on_input(RunInstructionsRunCommandDraftChanged),
              ]),
            ]),
          ]),
          html.div([attribute.class("editor-page__dialog-actions")], [
            html.button(
              [
                attribute.type_("button"),
                attribute.class(
                  "editor-page__dialog-button editor-page__dialog-button--secondary",
                ),
                event.on_click(SettingsCancelled),
              ],
              [html.text("Cancel")],
            ),
            html.button(
              [
                attribute.type_("submit"),
                attribute.class("editor-page__dialog-button"),
              ],
              [html.text("Apply")],
            ),
          ]),
        ],
      ),
    ],
  )
}
