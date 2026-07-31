import gleam/list
import gleam/option
import glot_core/api_action
import glot_core/public_action
import glot_core/run
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/execution_workflow
import glot_frontend/public/editor/file_workflow
import glot_frontend/public/editor/message.{
  type ExecutionMsg, RunFinished, RunSubmitted, SourceCodeChanged, TabKeyPressed,
  TabSelected, VersionRunFinished,
}
import glot_frontend/public/editor/model.{
  type Editor, type EditorTab, Editor, Workspace,
}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/tab_semantics
import glot_frontend/request_generation.{type Generation}

pub fn update(
  model: Editor,
  msg: ExecutionMsg,
) -> #(Editor, command.Command(ExecutionMsg)) {
  case msg {
    TabSelected(tab) -> #(select_tab(model, tab), command.none())

    TabKeyPressed(current, key) -> {
      let tabs = editor_tabs(model)
      case tab_semantics.keyboard_destination(tabs, current, key) {
        option.Some(tab) -> #(
          select_tab(model, tab),
          command.Focus(tab_semantics.tab_id(tab)),
        )
        option.None -> #(model, command.none())
      }
    }

    SourceCodeChanged(source_code, revision) -> {
      let next_model =
        file_workflow.update_selected_tab_content(model, source_code)
        |> fn(model) {
          Editor(
            ..model,
            workspace: Workspace(..model.workspace, editor_revision: revision),
          )
        }
      #(next_model, command.SaveDraft(draft_projection.write(next_model)))
    }

    RunSubmitted -> execution_workflow.run_snippet(model)

    RunFinished(generation, result) -> finish_run(model, generation, result)

    VersionRunFinished(language, _) if language != model.snippet.language -> #(
      model,
      command.none(),
    )

    VersionRunFinished(_, result) -> {
      case result {
        api_response.Success(Ok(run.SuccessfulRun(stdout:, ..))) -> #(
          Editor(
            ..model,
            operations: operations.record_version_info(model.operations, stdout),
          ),
          command.none(),
        )

        _ -> #(model, command.none())
      }
    }
  }
}

fn finish_run(
  model: Editor,
  generation: Generation(execution_operation.Stream),
  result: api_response.Response(run.RunResult),
) -> #(Editor, command.Command(ExecutionMsg)) {
  let next_operations = case result {
    api_response.Success(run_result) ->
      operations.complete_execution(model.operations, generation, run_result)
    api_response.ApiFailure(error) ->
      operations.fail_execution(
        model.operations,
        generation,
        api_response.error_message(error),
      )
    api_response.HttpFailure(_) ->
      operations.fail_execution(
        model.operations,
        generation,
        "Could not complete "
          <> api_action.to_string(api_action.public(public_action.RunAction))
          <> ".",
      )
  }
  case next_operations {
    option.None -> #(model, command.none())
    option.Some(next_operations) -> #(
      Editor(..model, operations: next_operations),
      command.none(),
    )
  }
}

fn select_tab(model: Editor, tab: EditorTab) -> Editor {
  Editor(
    ..model,
    workspace: Workspace(
      ..model.workspace,
      selected_tab: tab,
      editor_external_revision: model.workspace.editor_external_revision + 1,
    ),
  )
}

fn editor_tabs(model: Editor) -> List(EditorTab) {
  let file_tabs = file_tabs(list.length(model.snippet.files), 0)
  case model.snippet.stdin {
    option.Some(_) -> list.append(file_tabs, [model.StdinTab])
    option.None -> file_tabs
  }
}

fn file_tabs(count: Int, index: Int) -> List(EditorTab) {
  case index >= count {
    True -> []
    False -> [model.FileTab(index), ..file_tabs(count, index + 1)]
  }
}
