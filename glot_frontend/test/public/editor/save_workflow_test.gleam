import gleam/option
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/command
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/save_operation
import glot_frontend/public/editor/save_workflow
import support/editor_fixture

pub fn create_projects_the_complete_editor_state_into_a_request_test() {
  let custom = language.RunInstructions(["npm build"], "node dist.js")
  let base = ready.new(language.JavaScript, environment.defaults())
  let editor =
    model.Editor(
      ..base,
      snippet: model.Snippet(
        ..base.snippet,
        title: "Projected title",
        files: [snippet_model.File("app.js", "source")],
        stdin: option.Some("input"),
        run_instructions_override: option.Some(custom),
      ),
      save_draft: model.SaveDraft(visibility: snippet_model.Secret),
    )
  let #(saving, next_command) =
    save_workflow.save_snippet(
      editor,
      policy.CreateSnippet(snippet_model.Secret),
      True,
    )

  assert saving.snippet.visibility == snippet_model.Secret
  assert operations.save_state(saving.operations) == save_operation.Saving
  assert operations.console_owner(saving.operations) == operations.SaveConsole
  let assert command.Batch([
    command.CloseDialog("editor-page-save-dialog"),
    command.CreateSnippet(request, complete),
  ]) = next_command
  assert request.data.title == "Projected title"
  assert request.data.language == language.JavaScript
  assert request.data.visibility == snippet_model.Secret
  assert request.data.files == [snippet_model.File("app.js", "source")]
  assert request.data.stdin == "input"
  assert request.data.run_instructions == option.Some(custom)
  assert_callback_generation_is_current(
    saving,
    policy.CreateSnippet(snippet_model.Secret),
    complete,
  )
}

pub fn create_normalizes_absent_stdin_for_the_api_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())
  let #(_, next_command) =
    save_workflow.save_snippet(
      editor,
      policy.CreateSnippet(snippet_model.Unlisted),
      False,
    )
  let assert command.CreateSnippet(request, _) = next_command

  assert request.data.stdin == ""
}

pub fn owned_existing_snippet_updates_without_closing_the_dialog_test() {
  let editor = existing_editor()
  let #(saving, next_command) =
    save_workflow.save_snippet(
      editor,
      policy.UpdateSnippet("save-workflow", snippet_model.Public),
      False,
    )
  let assert command.UpdateSnippet(request, complete) = next_command

  assert request.slug == "save-workflow"
  assert request.data.visibility == editor.snippet.visibility
  assert_callback_generation_is_current(
    saving,
    policy.UpdateSnippet("save-workflow", snippet_model.Public),
    complete,
  )
}

pub fn non_owner_existing_snippet_is_created_as_a_copy_test() {
  let editor = existing_editor()
  let #(_, next_command) =
    save_workflow.save_snippet(
      editor,
      policy.CreateSnippet(snippet_model.Public),
      True,
    )
  let assert command.Batch([
    command.CloseDialog("editor-page-save-dialog"),
    command.CreateSnippet(request, _),
  ]) = next_command

  assert request.data.files == editor.snippet.files
  assert request.data.visibility == editor.snippet.visibility
}

fn existing_editor() -> model.Editor {
  let editor = ready.new(language.JavaScript, environment.defaults())
  model.Editor(
    ..editor,
    snippet: model.Snippet(
      ..editor.snippet,
      slug: option.Some("save-workflow"),
      owner_user_id: option.Some(editor_fixture.owner_id()),
      visibility: snippet_model.Public,
    ),
    save_draft: model.SaveDraft(visibility: snippet_model.Secret),
  )
}

fn assert_callback_generation_is_current(
  editor: model.Editor,
  expected_plan: policy.SavePlan,
  complete: fn(response.Response(snippet_dto.SnippetResponse)) ->
    message.SaveMsg,
) -> Nil {
  let fixture = editor_fixture.snippet("saved", "source")
  let assert message.SaveFinished(generation, plan, response.Success(_)) =
    complete(response.Success(fixture))
  assert plan == expected_plan
  let assert option.Some(_) =
    operations.succeed_save(editor.operations, generation, fixture.slug)
  Nil
}
