import gleam/option
import glot_core/route
import glot_core/snippet/snippet_dto
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type SaveMsg, SaveCancelled, SaveClicked, SaveConfirmed, SaveDialogClosed,
  SaveFinished, SaveVisibilityDraftSelected,
}
import glot_frontend/public/editor/model.{type Editor, Editor, SaveDraft}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/save_operation.{type Stream}
import glot_frontend/public/editor/save_workflow
import glot_frontend/request_generation.{type Generation}
import youid/uuid.{type Uuid}

pub fn update(
  model: Editor,
  msg: SaveMsg,
  current_user_id: option.Option(Uuid),
) -> #(Editor, command.Command(SaveMsg)) {
  case msg {
    SaveClicked ->
      case policy.save_decision(model, current_user_id) {
        policy.Authorized(policy.UpdateSnippet(slug, visibility)) ->
          save_workflow.save_snippet(
            model,
            policy.UpdateSnippet(slug, visibility),
            False,
          )
        policy.Authorized(policy.CreateSnippet(_)) | policy.LoginRequired -> #(
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

    SaveConfirmed ->
      case policy.save_decision(model, current_user_id) {
        policy.Authorized(plan) -> save_workflow.save_snippet(model, plan, True)
        policy.LoginRequired -> #(model, command.none())
      }

    SaveFinished(generation, plan, result) ->
      finish_save(model, generation, plan, result)
  }
}

fn finish_save(
  model: Editor,
  generation: Generation(Stream),
  plan: policy.SavePlan,
  result: api_response.Response(snippet_dto.SnippetResponse),
) -> #(Editor, command.Command(SaveMsg)) {
  case result {
    api_response.Success(response) -> {
      case
        operations.succeed_save(model.operations, generation, response.slug)
      {
        option.None -> #(model, command.none())
        option.Some(next_operations) -> {
          let next_model = Editor(..model, operations: next_operations)
          let clear_draft_command =
            command.ClearDraft(draft_projection.target(next_model))
          case plan {
            policy.UpdateSnippet(_, _) -> #(next_model, clear_draft_command)
            policy.CreateSnippet(_) -> {
              let navigate =
                command.Navigate(
                  route.to_string(route.Public(route.Snippet(response.slug))),
                )
              #(next_model, command.batch([clear_draft_command, navigate]))
            }
          }
        }
      }
    }

    api_response.ApiFailure(error) ->
      update_failed_save(
        model,
        operations.fail_save(
          model.operations,
          generation,
          api_response.error_message(error),
        ),
      )

    api_response.HttpFailure(_) ->
      update_failed_save(
        model,
        operations.fail_save(
          model.operations,
          generation,
          "Could not complete " <> policy.plan_action_name(plan) <> ".",
        ),
      )
  }
}

fn update_failed_save(
  model: Editor,
  next_operations: option.Option(operations.Operations),
) -> #(Editor, command.Command(SaveMsg)) {
  case next_operations {
    option.None -> #(model, command.none())
    option.Some(next_operations) -> #(
      Editor(..model, operations: next_operations),
      command.none(),
    )
  }
}

fn focus_editor() -> command.Command(msg) {
  command.Focus(ids.editor)
}

fn reset_save_dialog_draft(model: Editor) -> Editor {
  Editor(..model, save_draft: SaveDraft(visibility: model.snippet.visibility))
}
