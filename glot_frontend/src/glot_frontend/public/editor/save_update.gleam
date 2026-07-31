import gleam/option
import glot_core/route
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/execution
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type SaveMsg, SaveCancelled, SaveClicked, SaveConfirmed, SaveDialogClosed,
  SaveFinished, SaveVisibilityDraftSelected,
}
import glot_frontend/public/editor/model.{
  type Editor, Editor, Operations, SaveDraft,
}
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/save_workflow
import youid/uuid.{type Uuid}

pub fn update(
  model: Editor,
  msg: SaveMsg,
  current_user_id: option.Option(Uuid),
) -> #(Editor, command.Command(SaveMsg)) {
  case msg {
    SaveClicked ->
      case
        model.snippet.slug,
        current_user_id,
        policy.is_owner(model, current_user_id)
      {
        option.Some(_), option.Some(_), True ->
          save_workflow.save_snippet(model, current_user_id, False)
        _, _, _ -> #(
          reset_save_dialog_draft(model),
          command.OpenDialog(ids.save_dialog),
        )
      }

    SaveVisibilityDraftSelected(visibility) -> #(
      Editor(..model, save_draft: SaveDraft(visibility: visibility)),
      command.none(),
    )

    SaveCancelled -> #(
      reset_save_dialog_draft(model),
      command.CloseDialog(ids.save_dialog),
    )

    SaveDialogClosed -> #(reset_save_dialog_draft(model), focus_editor())

    SaveConfirmed -> save_workflow.save_snippet(model, current_user_id, True)

    SaveFinished(generation, _)
      if generation != model.operations.save_generation
    -> #(model, command.none())

    SaveFinished(_, result) -> {
      case result {
        api_response.Success(response) -> {
          let next_model =
            Editor(
              ..model,
              operations: Operations(
                ..model.operations,
                save_state: execution.Saved(response.slug),
              ),
            )
          let clear_draft_command =
            command.ClearDraft(draft_projection.target(next_model))
          case policy.save_operation(model, current_user_id) {
            policy.UpdateSnippet(_) -> #(next_model, clear_draft_command)
            policy.CreateSnippet -> {
              let navigate =
                command.Navigate(
                  route.to_string(route.Public(route.Snippet(response.slug))),
                )
              #(next_model, command.batch([clear_draft_command, navigate]))
            }
          }
        }

        api_response.ApiFailure(error) -> #(
          Editor(
            ..model,
            operations: Operations(
              ..model.operations,
              save_state: execution.SaveError(api_response.error_message(error)),
            ),
          ),
          command.none(),
        )

        api_response.HttpFailure(_) -> #(
          Editor(
            ..model,
            operations: Operations(
              ..model.operations,
              save_state: execution.SaveError(
                "Could not complete "
                <> policy.action_name(model, current_user_id)
                <> ".",
              ),
            ),
          ),
          command.none(),
        )
      }
    }
  }
}

fn focus_editor() -> command.Command(msg) {
  command.Focus(ids.editor)
}

fn reset_save_dialog_draft(model: Editor) -> Editor {
  Editor(..model, save_draft: SaveDraft(visibility: model.snippet.visibility))
}
