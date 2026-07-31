import gleam/option
import glot_core/snippet/snippet_dto
import glot_frontend/public/editor/command
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{type SaveMsg, SaveFinished}
import glot_frontend/public/editor/model.{type Editor, Editor, Snippet}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/policy

pub fn save_snippet(
  model: Editor,
  plan: policy.SavePlan,
  close_dialog: Bool,
) -> #(Editor, command.Command(SaveMsg)) {
  let visibility = policy.plan_visibility(plan)
  let #(next_operations, generation) = operations.begin_save(model.operations)
  let data =
    snippet_dto.SnippetData(
      title: model.snippet.title,
      language: model.snippet.language,
      visibility: visibility,
      stdin: stdin_to_string(model.snippet.stdin),
      run_instructions: model.snippet.run_instructions_override,
      files: model.snippet.files,
    )

  let save_command = case plan {
    policy.CreateSnippet(_) ->
      command.CreateSnippet(
        snippet_dto.CreateSnippetRequest(data: data),
        fn(result) { SaveFinished(generation, plan, result) },
      )

    policy.UpdateSnippet(slug, _) ->
      command.UpdateSnippet(
        snippet_dto.UpdateSnippetRequest(slug: slug, data: data),
        fn(result) { SaveFinished(generation, plan, result) },
      )
  }

  let combined_command = case close_dialog {
    True -> command.batch([command.CloseDialog(ids.save_dialog), save_command])
    False -> save_command
  }

  #(
    Editor(
      ..model,
      snippet: Snippet(..model.snippet, visibility: visibility),
      operations: next_operations,
    ),
    combined_command,
  )
}

fn stdin_to_string(stdin: option.Option(String)) -> String {
  case stdin {
    option.Some(content) -> content
    option.None -> ""
  }
}
