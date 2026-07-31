import gleam/dynamic/decode
import gleam/list
import glot_frontend/public/editor/dialog_controls
import glot_frontend/public/editor/file_policy
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type FileMsg, AddEntryCancelled, AddEntryDialogClosed, AddEntryFilenameChanged,
  AddEntrySubmitted, EditEntryCancelled, EditEntryDeleted, EditEntryDialogClosed,
  EditEntryFilenameChanged, EditEntrySubmitted,
}
import glot_frontend/public/editor/model.{
  type Editor, AddFileEntry, AddStdinEntry, FileTab, StdinTab,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn add_dialog(model: Editor) -> Element(FileMsg) {
  html.dialog(
    [
      attribute.id(ids.add_entry_dialog),
      attribute.class("editor-page__dialog"),
      attribute.attribute("aria-label", "Add editor entry"),
      event.on("close", decode.success(AddEntryDialogClosed)),
    ],
    [
      html.form(
        [
          attribute.class("editor-page__dialog-form"),
          event.on_submit(fn(_) { AddEntrySubmitted }),
        ],
        [
          html.div(
            [
              attribute.class("editor-page__dialog-toggle-group"),
              attribute.attribute("role", "group"),
              attribute.attribute("aria-label", "Entry type"),
            ],
            [
              dialog_controls.entry_kind_toggle(
                "File",
                model.entry_drafts.add.kind == AddFileEntry,
                AddFileEntry,
              ),
              dialog_controls.entry_kind_toggle(
                "stdin",
                model.entry_drafts.add.kind == AddStdinEntry,
                AddStdinEntry,
              ),
            ],
          ),
          add_entry_fields_view(model),
          html.div([attribute.class("editor-page__dialog-actions")], [
            html.button(
              [
                attribute.type_("button"),
                attribute.class(
                  "editor-page__dialog-button editor-page__dialog-button--secondary",
                ),
                event.on_click(AddEntryCancelled),
              ],
              [html.text("Cancel")],
            ),
            html.button(
              [
                attribute.type_("submit"),
                attribute.class("editor-page__dialog-button"),
                attribute.disabled(!file_policy.can_submit_add_entry(model)),
              ],
              [html.text("Add")],
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn edit_dialog(model: Editor) -> Element(FileMsg) {
  html.dialog(
    [
      attribute.id(ids.edit_entry_dialog),
      attribute.class("editor-page__dialog"),
      attribute.attribute("aria-label", "Edit editor entry"),
      event.on("close", decode.success(EditEntryDialogClosed)),
    ],
    [
      html.form(
        [
          attribute.class("editor-page__dialog-form"),
          event.on_submit(fn(_) { EditEntrySubmitted }),
        ],
        edit_entry_dialog_children(model),
      ),
    ],
  )
}

fn edit_entry_dialog_children(model: Editor) -> List(Element(FileMsg)) {
  case model.workspace.selected_tab {
    FileTab(_) -> [
      html.label(
        [
          attribute.for("editor-page-edit-entry-input"),
          attribute.class("editor-page__dialog-label"),
        ],
        [html.text("Filename")],
      ),
      html.input([
        attribute.id("editor-page-edit-entry-input"),
        attribute.name("filename"),
        attribute.type_("text"),
        attribute.maxlength(30),
        attribute.value(model.entry_drafts.edit.filename),
        attribute.autofocus(True),
        attribute.class("editor-page__dialog-input"),
        event.on_input(EditEntryFilenameChanged),
      ]),
      html.div(
        [attribute.class("editor-page__dialog-actions")],
        file_edit_actions(model),
      ),
    ]

    StdinTab -> [
      html.p([attribute.class("editor-page__dialog-copy")], [
        html.text("Delete the <stdin> tab and keep only source files."),
      ]),
      html.div([attribute.class("editor-page__dialog-actions")], [
        html.button(
          [
            attribute.type_("button"),
            attribute.class(
              "editor-page__dialog-button editor-page__dialog-button--danger",
            ),
            event.on_click(EditEntryDeleted),
          ],
          [html.text("Delete <stdin>")],
        ),
        html.button(
          [
            attribute.type_("button"),
            attribute.class(
              "editor-page__dialog-button editor-page__dialog-button--secondary",
            ),
            event.on_click(EditEntryCancelled),
          ],
          [html.text("Close")],
        ),
      ]),
    ]
  }
}

fn file_edit_actions(model: Editor) -> List(Element(FileMsg)) {
  let delete_button = case file_policy.can_delete_selected_file(model) {
    True -> [
      html.button(
        [
          attribute.type_("button"),
          attribute.class(
            "editor-page__dialog-button editor-page__dialog-button--danger",
          ),
          event.on_click(EditEntryDeleted),
        ],
        [html.text("Delete file")],
      ),
    ]

    False -> []
  }

  list.append(delete_button, [
    html.button(
      [
        attribute.type_("button"),
        attribute.class(
          "editor-page__dialog-button editor-page__dialog-button--secondary",
        ),
        event.on_click(EditEntryCancelled),
      ],
      [html.text("Cancel")],
    ),
    html.button(
      [
        attribute.type_("submit"),
        attribute.class("editor-page__dialog-button"),
        attribute.disabled(!file_policy.can_submit_edit_entry(model)),
      ],
      [html.text("Save")],
    ),
  ])
}

fn add_entry_fields_view(model: Editor) -> Element(FileMsg) {
  case model.entry_drafts.add.kind {
    AddFileEntry ->
      html.div([attribute.class("editor-page__dialog-panel")], [
        html.label(
          [
            attribute.for("editor-page-filename-input"),
            attribute.class("editor-page__dialog-label"),
          ],
          [html.text("Filename")],
        ),
        html.input([
          attribute.id("editor-page-filename-input"),
          attribute.name("filename"),
          attribute.type_("text"),
          attribute.maxlength(30),
          attribute.value(model.entry_drafts.add.filename),
          attribute.autofocus(True),
          attribute.class("editor-page__dialog-input"),
          event.on_input(AddEntryFilenameChanged),
        ]),
      ])

    AddStdinEntry ->
      html.div([attribute.class("editor-page__dialog-panel")], [
        html.p([attribute.class("editor-page__dialog-copy")], [
          html.text(file_policy.add_stdin_message(model.snippet.stdin)),
        ]),
      ])
  }
}
