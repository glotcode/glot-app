import glot_core/language
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/command
import glot_frontend/public/editor/message
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/snippet_info_update

pub fn click_requests_the_snippet_info_dialog_without_changing_the_editor_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())

  assert snippet_info_update.update(editor, message.SnippetInfoClicked)
    == #(editor, command.OpenDialog("editor-page-snippet-info-dialog"))
}

pub fn dismiss_requests_dialog_closure_without_changing_the_editor_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())

  assert snippet_info_update.update(editor, message.SnippetInfoDismissed)
    == #(editor, command.CloseDialog("editor-page-snippet-info-dialog"))
}

pub fn browser_close_restores_editor_focus_without_changing_the_editor_test() {
  let editor = ready.new(language.JavaScript, environment.defaults())

  assert snippet_info_update.update(editor, message.SnippetInfoClosed)
    == #(editor, command.Focus("code-editor-input"))
}
