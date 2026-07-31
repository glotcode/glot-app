import gleam/dynamic/decode
import gleam/option
import glot_core/route
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/dialog_controls
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type SaveMsg, SaveCancelled, SaveConfirmed, SaveDialogClosed,
  SaveVisibilityDraftSelected,
}
import glot_frontend/public/editor/model.{type Editor}
import glot_frontend/public/editor/policy
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid.{type Uuid}

pub fn view(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> Element(SaveMsg) {
  let children = case current_user_id {
    option.None -> [
      html.div(
        [attribute.class("editor-page__dialog-form")],
        save_dialog_children(model, current_user_id),
      ),
    ]

    option.Some(_) -> [
      html.form(
        [
          attribute.class("editor-page__dialog-form"),
          event.on_submit(fn(_) { SaveConfirmed }),
        ],
        save_dialog_children(model, current_user_id),
      ),
    ]
  }

  html.dialog(
    [
      attribute.id(ids.save_dialog),
      attribute.class("editor-page__dialog"),
      attribute.attribute("aria-label", "Save snippet"),
      event.on("close", decode.success(SaveDialogClosed)),
    ],
    children,
  )
}

fn save_dialog_children(
  model: Editor,
  current_user_id: option.Option(Uuid),
) -> List(Element(SaveMsg)) {
  case current_user_id {
    option.None -> [
      html.h2([attribute.class("editor-page__dialog-label")], [
        html.text("Save snippet"),
      ]),
      html.p([attribute.class("editor-page__dialog-copy")], [
        html.text("You need to log in before you can save snippets. "),
        html.a(
          [
            web_route.href(route.Public(route.Login)),
            attribute.class("editor-page__dialog-link"),
          ],
          [html.text("Go to login")],
        ),
        html.text("."),
      ]),
      html.div([attribute.class("editor-page__dialog-actions")], [
        html.button(
          [
            attribute.type_("button"),
            attribute.class(
              "editor-page__dialog-button editor-page__dialog-button--secondary",
            ),
            event.on_click(SaveCancelled),
          ],
          [html.text("Close")],
        ),
      ]),
    ]

    option.Some(_) ->
      case policy.can_choose_visibility(model, current_user_id) {
        True -> [
          html.p([attribute.class("editor-page__dialog-label")], [
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
                model.save_draft.visibility,
                SaveVisibilityDraftSelected,
              ),
              dialog_controls.visibility_option(
                "Unlisted",
                "Available through the link only.",
                snippet_model.Unlisted,
                model.save_draft.visibility,
                SaveVisibilityDraftSelected,
              ),
              dialog_controls.visibility_option(
                "Secret",
                "Visible only to you.",
                snippet_model.Secret,
                model.save_draft.visibility,
                SaveVisibilityDraftSelected,
              ),
            ],
          ),
          html.div([attribute.class("editor-page__dialog-actions")], [
            html.button(
              [
                attribute.type_("button"),
                attribute.class(
                  "editor-page__dialog-button editor-page__dialog-button--secondary",
                ),
                event.on_click(SaveCancelled),
              ],
              [html.text("Cancel")],
            ),
            html.button(
              [
                attribute.type_("submit"),
                attribute.class("editor-page__dialog-button"),
              ],
              [html.text("Save")],
            ),
          ]),
        ]

        False -> [
          html.h2([attribute.class("editor-page__dialog-label")], [
            html.text("Save snippet"),
          ]),
          html.p([attribute.class("editor-page__dialog-copy")], [
            html.text(
              "You do not own this snippet. Saving will create a new snippet in your account.",
            ),
          ]),
          html.div([attribute.class("editor-page__dialog-actions")], [
            html.button(
              [
                attribute.type_("button"),
                attribute.class(
                  "editor-page__dialog-button editor-page__dialog-button--secondary",
                ),
                event.on_click(SaveCancelled),
              ],
              [html.text("Cancel")],
            ),
            html.button(
              [
                attribute.type_("submit"),
                attribute.class("editor-page__dialog-button"),
              ],
              [html.text("Save new snippet")],
            ),
          ]),
        ]
      }
  }
}
