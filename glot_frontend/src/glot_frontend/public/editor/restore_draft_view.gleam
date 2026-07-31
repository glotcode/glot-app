import gleam/dynamic/decode
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type RestoreDraftMsg, RestoreDraftAccepted, RestoreDraftClosed,
  RestoreDraftDeclined,
}
import glot_frontend/public/editor/model.{
  type Editor, NoRestoreDraft, RestoreDraftPending,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Editor, now: Timestamp) -> Element(RestoreDraftMsg) {
  let children = case model.restore_draft {
    RestoreDraftPending(draft) -> [
      html.div([attribute.class("editor-page__dialog-form")], [
        html.h2([attribute.class("editor-page__dialog-label")], [
          html.text("Restore draft"),
        ]),
        html.p([attribute.class("editor-page__dialog-copy")], [
          html.text(restore_draft_copy(
            model.snippet.slug,
            draft.saved_at_ms,
            now,
          )),
        ]),
        html.div([attribute.class("editor-page__dialog-actions")], [
          html.button(
            [
              attribute.type_("button"),
              attribute.class(
                "editor-page__dialog-button editor-page__dialog-button--secondary",
              ),
              event.on_click(RestoreDraftDeclined),
            ],
            [html.text("No")],
          ),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("editor-page__dialog-button"),
              event.on_click(RestoreDraftAccepted),
            ],
            [html.text("Yes")],
          ),
        ]),
      ]),
    ]

    NoRestoreDraft -> []
  }

  html.dialog(
    [
      attribute.id(ids.restore_draft_dialog),
      attribute.class("editor-page__dialog"),
      attribute.attribute("aria-label", "Restore draft"),
      event.on("close", decode.success(RestoreDraftClosed)),
    ],
    children,
  )
}

fn restore_draft_copy(
  slug: option.Option(String),
  saved_at_ms: Int,
  now: Timestamp,
) -> String {
  let saved_at =
    timestamp_helpers.relative_label(
      timestamp_helpers.from_unix_milliseconds(saved_at_ms),
      now,
    )

  case slug {
    option.None ->
      "A local draft saved "
      <> saved_at
      <> " was found for this new snippet. Do you want to restore it?"
    option.Some(_) ->
      "A newer local draft saved "
      <> saved_at
      <> " was found for this snippet. Do you want to restore your unsaved local changes?"
  }
}
