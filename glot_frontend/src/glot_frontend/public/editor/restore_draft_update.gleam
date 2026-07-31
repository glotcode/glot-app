import gleam/option
import glot_core/language
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/draft_workflow
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type RestoreDraftMsg, ExistingDraftLoaded, NewDraftLoaded,
  RestoreDraftAccepted, RestoreDraftClosed, RestoreDraftDeclined,
}
import glot_frontend/public/editor/model.{
  type Editor, type RestoreDraftState, Editor, NoRestoreDraft,
  RestoreDraftPending,
}

pub fn update(
  model: Editor,
  msg: RestoreDraftMsg,
) -> #(Editor, command.Command(RestoreDraftMsg)) {
  case msg {
    NewDraftLoaded(language_slug, stored) ->
      case
        model.snippet.slug == option.None
        && language.to_string(model.snippet.language) == language_slug
      {
        True -> {
          let next_command = case stored {
            option.Some(_) ->
              command.OpenDialogNextFrame(ids.restore_draft_dialog)
            option.None -> command.none()
          }
          #(Editor(..model, restore_draft: from_option(stored)), next_command)
        }
        False -> #(model, command.none())
      }

    ExistingDraftLoaded(slug, updated_at, stored) ->
      draft_workflow.apply_loaded_draft(model, slug, updated_at, stored)

    RestoreDraftAccepted ->
      case model.restore_draft {
        RestoreDraftPending(draft) -> #(
          draft_workflow.apply_editor_draft(model, draft.draft),
          command.CloseDialog(ids.restore_draft_dialog),
        )
        NoRestoreDraft -> #(model, command.none())
      }

    RestoreDraftDeclined -> #(
      Editor(..model, restore_draft: NoRestoreDraft),
      command.batch([
        command.CloseDialog(ids.restore_draft_dialog),
        command.ClearDraft(draft_projection.target(model)),
      ]),
    )

    RestoreDraftClosed -> #(
      Editor(..model, restore_draft: NoRestoreDraft),
      command.Focus(ids.editor),
    )
  }
}

fn from_option(
  stored: option.Option(draft.StoredEditorDraft),
) -> RestoreDraftState {
  case stored {
    option.Some(draft) -> RestoreDraftPending(draft)
    option.None -> NoRestoreDraft
  }
}
