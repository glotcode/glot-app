import glot_frontend/public/editor/command
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type SnippetInfoMsg, SnippetInfoClicked, SnippetInfoClosed,
  SnippetInfoDismissed,
}
import glot_frontend/public/editor/model.{type Editor}

pub fn update(
  model: Editor,
  msg: SnippetInfoMsg,
) -> #(Editor, command.Command(SnippetInfoMsg)) {
  case msg {
    SnippetInfoClicked -> #(model, command.OpenDialog(ids.snippet_info_dialog))
    SnippetInfoDismissed -> #(
      model,
      command.CloseDialog(ids.snippet_info_dialog),
    )
    SnippetInfoClosed -> #(model, command.Focus(ids.editor))
  }
}
