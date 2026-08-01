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
  type ExecutionMsg, RunCancellationDelayElapsed, RunCancellationSubmitted,
  RunFinished, RunSubmitted, SourceCodeChanged, TabKeyPressed, TabSelected,
  VersionRunFinished,
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
    TabSelected(tab) -> select_requested_tab(model, tab)

    TabKeyPressed(current, key) -> {
      let tabs = available_tabs(model)
      case tab_semantics.keyboard_destination(tabs, current, key) {
        option.Some(tab) -> #(
          select_tab(model, tab),
          command.Focus(tab_semantics.tab_id(tab)),
        )
        option.None -> #(model, command.none())
      }
    }

    SourceCodeChanged(source_code, revision) -> {
      case file_workflow.update_selected_tab_content(model, source_code) {
        option.None -> #(model, command.none())
        option.Some(changed) -> {
          let next_model =
            Editor(
              ..changed,
              workspace: Workspace(
                ..changed.workspace,
                editor_revision: revision,
              ),
            )
          #(next_model, command.SaveDraft(draft_projection.write(next_model)))
        }
      }
    }

    RunSubmitted ->
      case operations.execution_is_running(model.operations) {
        True -> #(model, command.none())
        False -> execution_workflow.run_snippet(model)
      }

    RunCancellationDelayElapsed(generation) ->
      offer_cancellation(model, generation)

    RunCancellationSubmitted -> cancel_run(model)

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

fn offer_cancellation(
  model: Editor,
  generation: Generation(execution_operation.Stream),
) -> #(Editor, command.Command(ExecutionMsg)) {
  case operations.offer_execution_cancellation(model.operations, generation) {
    option.None -> #(model, command.none())
    option.Some(next_operations) -> #(
      Editor(..model, operations: next_operations),
      command.none(),
    )
  }
}

fn cancel_run(model: Editor) -> #(Editor, command.Command(ExecutionMsg)) {
  case operations.cancel_execution(model.operations) {
    option.None -> #(model, command.none())
    option.Some(next_operations) -> #(
      Editor(..model, operations: next_operations),
      command.CancelRun,
    )
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

fn select_requested_tab(
  model: Editor,
  requested: EditorTab,
) -> #(Editor, command.Command(ExecutionMsg)) {
  let tabs = available_tabs(model)
  case tab_semantics.select_tab(tabs, requested) {
    tab_semantics.SelectionBlocked -> #(model, command.none())
    tab_semantics.SelectTab(tab) -> #(select_tab(model, tab), command.none())
  }
}

fn available_tabs(model: Editor) -> List(EditorTab) {
  tab_semantics.available_tabs(
    list.length(model.snippet.files),
    model.snippet.stdin,
  )
}
