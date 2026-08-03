import gleam/option
import glot_core/language
import glot_frontend/public/editor/command
import glot_frontend/public/editor/execution_update
import glot_frontend/public/editor/file_update
import glot_frontend/public/editor/message.{
  type EditorMsg, Execution, File, Metadata, RestoreDraft, Save, Settings,
  SnippetInfo, TabKeyPressed, TabSelected,
}
import glot_frontend/public/editor/metadata_update
import glot_frontend/public/editor/model.{type Editor}
import glot_frontend/public/editor/restore_draft_update
import glot_frontend/public/editor/save_update
import glot_frontend/public/editor/settings_update
import glot_frontend/public/editor/snippet_info_update
import youid/uuid.{type Uuid}

pub fn update(
  model: Editor,
  msg: EditorMsg,
  current_user_id: option.Option(Uuid),
) -> #(Editor, command.Command(EditorMsg)) {
  case language.is_writable(model.snippet.language), msg {
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

fn map_command(
  transition: #(Editor, command.Command(a)),
  wrap: fn(a) -> EditorMsg,
) -> #(Editor, command.Command(EditorMsg)) {
  let #(model, next) = transition
  #(model, command.map(next, wrap))
}
