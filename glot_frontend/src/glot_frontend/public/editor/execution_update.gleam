import gleam/list
import gleam/option
import glot_core/api_action
import glot_core/language
import glot_core/public_action
import glot_core/run
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/execution_operation
import glot_frontend/public/editor/file_workflow
import glot_frontend/public/editor/message.{
  type ExecutionMsg, RunFinished, RunSubmitted, SourceCodeChanged, TabKeyPressed,
  TabSelected, VersionRunFinished,
}
import glot_frontend/public/editor/model.{
  type Editor, type EditorTab, Editor, ExecutionConsole, Operations, Workspace,
}
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/tab_semantics

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

    RunSubmitted -> {
      let #(next_execution, generation) =
        execution_operation.begin(model.operations.execution)
      let request =
        run.RunRequest(
          image: language.container_image(model.snippet.language),
          payload: run.RunRequestPayload(
            run_instructions: run_instructions.effective_run_instructions(model),
            files: model.snippet.files,
            stdin: model.snippet.stdin,
          ),
        )

      #(
        Editor(
          ..model,
          operations: Operations(
            ..model.operations,
            execution: next_execution,
            console_owner: ExecutionConsole,
          ),
        ),
        command.RunCode(request, fn(result) { RunFinished(generation, result) }),
      )
    }

    RunFinished(generation, result) -> {
      case
        execution_operation.is_current(model.operations.execution, generation)
      {
        False -> #(model, command.none())
        True -> finish_run(model, result)
      }
    }

    VersionRunFinished(language, _) if language != model.snippet.language -> #(
      model,
      command.none(),
    )

    VersionRunFinished(_, result) -> {
      case result {
        api_response.Success(Ok(run.SuccessfulRun(stdout:, ..))) -> #(
          Editor(
            ..model,
            operations: Operations(
              ..model.operations,
              execution: execution_operation.record_version_info(
                model.operations.execution,
                stdout,
              ),
            ),
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
  result: api_response.Response(run.RunResult),
) -> #(Editor, command.Command(ExecutionMsg)) {
  case result {
    api_response.Success(run_result) -> #(
      Editor(
        ..model,
        operations: Operations(
          ..model.operations,
          execution: execution_operation.complete(
            model.operations.execution,
            run_result,
          ),
        ),
      ),
      command.none(),
    )

    api_response.ApiFailure(error) -> #(
      Editor(
        ..model,
        operations: Operations(
          ..model.operations,
          execution: execution_operation.fail(
            model.operations.execution,
            api_response.error_message(error),
          ),
        ),
      ),
      command.none(),
    )

    api_response.HttpFailure(_) -> #(
      Editor(
        ..model,
        operations: Operations(
          ..model.operations,
          execution: execution_operation.fail(
            model.operations.execution,
            "Could not complete "
              <> api_action.to_string(api_action.public(public_action.RunAction))
              <> ".",
          ),
        ),
      ),
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
