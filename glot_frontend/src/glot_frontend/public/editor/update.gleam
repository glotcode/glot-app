import gleam/list
import gleam/option
import glot_core/language
import glot_frontend/public/editor/command
import glot_frontend/public/editor/execution_update
import glot_frontend/public/editor/file_update
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/message as code_editor_message
import glot_frontend/public/editor/code_editor/update as code_editor_update
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/file_workflow
import glot_frontend/public/editor/message.{
  type EditorMsg, CodeEditor, Execution, File, Metadata, RestoreDraft,
  RunSubmitted, Save, SaveClicked, Settings, SnippetInfo, TabKeyPressed,
  TabSelected, UnfocusClicked,
}
import glot_frontend/public/editor/metadata_update
import glot_frontend/public/editor/model.{type Editor, Editor, Workspace}
import glot_frontend/public/editor/restore_draft_update
import glot_frontend/public/editor/save_update
import glot_frontend/public/editor/settings_update
import glot_frontend/public/editor/snippet_info_update
import glot_frontend/public/editor/workspace
import youid/uuid.{type Uuid}

pub fn update(
  model: Editor,
  msg: EditorMsg,
  current_user_id: option.Option(Uuid),
) -> #(Editor, command.Command(EditorMsg)) {
  case language.is_writable(model.snippet.language), msg {
    _, UnfocusClicked -> #(model, command.Blur(ids.editor))
    _, CodeEditor(msg) -> code_editor(model, msg, current_user_id)
    False, SnippetInfo(msg) ->
      snippet_info_update.update(model, msg)
      |> map_command(SnippetInfo)
    False, Execution(TabSelected(tab)) ->
      execution_update.update(model, TabSelected(tab))
      |> map_command(Execution)
    False, Execution(TabKeyPressed(tab, key)) ->
      execution_update.update(model, TabKeyPressed(tab, key))
      |> map_command(Execution)
    False, _ -> #(model, command.none())
    True, RestoreDraft(msg) ->
      restore_draft_update.update(model, msg)
      |> map_command(RestoreDraft)
    True, Metadata(msg) ->
      metadata_update.update(model, msg)
      |> map_command(Metadata)
    True, File(msg) -> file_update.update(model, msg) |> map_command(File)
    True, Settings(msg) ->
      settings_update.update(model, msg)
      |> map_command(Settings)
    True, Save(msg) ->
      save_update.update(model, msg, current_user_id)
      |> map_command(Save)
    True, SnippetInfo(msg) ->
      snippet_info_update.update(model, msg)
      |> map_command(SnippetInfo)
    True, Execution(msg) ->
      execution_update.update(model, msg)
      |> map_command(Execution)
  }
}

/// The code editor owns the document. Everything the page needs from it — the
/// current text, Run, and Save — arrives as an outbound event, so the snippet
/// stays in step with the editor within the same update.
fn code_editor(
  model: Editor,
  msg: code_editor_message.Msg,
  current_user_id: option.Option(Uuid),
) -> #(Editor, command.Command(EditorMsg)) {
  let #(next_editor, browser, outbound) =
    code_editor_update.update(model.workspace.editor, msg)
  let next_model =
    Editor(
      ..model,
      workspace: Workspace(..model.workspace, editor: next_editor),
    )

  list.fold(
    outbound,
    #(
      next_model,
      [command.CodeEditor(browser_command.map(browser, CodeEditor))],
    ),
    fn(accumulated, event) {
      let #(current, commands) = accumulated
      let #(updated, next) = apply_outbound(current, event, current_user_id)
      #(updated, list.append(commands, [next]))
    },
  )
  |> fn(result) {
    let #(final, commands) = result
    #(final, command.batch(commands))
  }
}

fn apply_outbound(
  model: Editor,
  event: code_editor_message.Outbound,
  current_user_id: option.Option(Uuid),
) -> #(Editor, command.Command(EditorMsg)) {
  case event {
    code_editor_message.DocumentChanged -> {
      let content = workspace.selected_text(model.workspace)
      case file_workflow.update_selected_tab_content(model, content) {
        option.None -> #(model, command.none())
        option.Some(changed) -> #(
          changed,
          command.SaveDraft(draft_projection.write(changed)),
        )
      }
    }
    code_editor_message.RunRequested ->
      execution_update.update(model, RunSubmitted) |> map_command(Execution)
    code_editor_message.SaveRequested ->
      save_update.update(model, SaveClicked, current_user_id)
      |> map_command(Save)
  }
}

fn map_command(
  transition: #(Editor, command.Command(a)),
  wrap: fn(a) -> EditorMsg,
) -> #(Editor, command.Command(EditorMsg)) {
  let #(model, next) = transition
  #(model, command.map(next, wrap))
}
