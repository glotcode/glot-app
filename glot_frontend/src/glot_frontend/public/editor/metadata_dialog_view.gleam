import gleam/dynamic/decode
import gleam/option
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/dialog_controls
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type Msg, EditMetadataCancelled, EditMetadataDialogClosed,
  EditMetadataSubmitted, EditMetadataVisibilitySelected, TitleDraftChanged,
}
import glot_frontend/public/editor/model.{type RealModel}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: RealModel) -> Element(Msg) {
  html.dialog(
    [
      attribute.id(ids.edit_metadata_dialog),
      attribute.class("editor-page__dialog"),
      attribute.attribute("aria-label", "Edit snippet metadata"),
      event.on("close", decode.success(EditMetadataDialogClosed)),
    ],
    [
      html.form(
        [
          attribute.class("editor-page__dialog-form"),
          event.on_submit(fn(_) { EditMetadataSubmitted }),
        ],
        [
          html.h2([attribute.class("editor-page__dialog-label")], [
            html.text("Edit metadata"),
          ]),
          html.div([attribute.class("editor-page__dialog-section")], [
            html.label(
              [
                attribute.for("editor-page-title-input"),
                attribute.class("editor-page__dialog-sublabel"),
              ],
              [html.text("Title")],
            ),
            html.input([
              attribute.id("editor-page-title-input"),
              attribute.name("title"),
              attribute.type_("text"),
              attribute.value(model.title_draft),
              attribute.autofocus(True),
              attribute.class("editor-page__dialog-input"),
              event.on_input(TitleDraftChanged),
            ]),
          ]),
          visibility_section(model),
          html.div([attribute.class("editor-page__dialog-actions")], [
            html.button(
              [
                attribute.type_("button"),
                attribute.class(
                  "editor-page__dialog-button editor-page__dialog-button--secondary",
                ),
                event.on_click(EditMetadataCancelled),
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

fn visibility_section(model: RealModel) -> Element(Msg) {
  case model.slug {
    option.None -> html.div([], [])
    option.Some(_) ->
      html.div([attribute.class("editor-page__dialog-section")], [
        html.p([attribute.class("editor-page__dialog-sublabel")], [
          html.text("Visibility"),
        ]),
        html.div(
          [
            attribute.class("editor-page__dialog-panel"),
            attribute.attribute("role", "group"),
            attribute.attribute("aria-label", "Visibility"),
          ],
          [
            dialog_controls.visibility_option(
              "Public",
              "Visible to everyone.",
              snippet_model.Public,
              model.save_visibility_draft,
              EditMetadataVisibilitySelected,
            ),
            dialog_controls.visibility_option(
              "Unlisted",
              "Available through the link only.",
              snippet_model.Unlisted,
              model.save_visibility_draft,
              EditMetadataVisibilitySelected,
            ),
            dialog_controls.visibility_option(
              "Secret",
              "Visible only to you.",
              snippet_model.Secret,
              model.save_visibility_draft,
              EditMetadataVisibilitySelected,
            ),
          ],
        ),
      ])
  }
}
