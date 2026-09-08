import gleam/list
import gleam/option
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/code_editor/message as code_editor_message
import glot_frontend/public/editor/code_editor/model as code_editor_model
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/message
import glot_frontend/public/editor/model
import glot_frontend/public/editor/update as editor_update
import glot_frontend/public/editor/workspace
import support/editor_scenario

pub fn typing_updates_the_snippet_and_persists_the_draft_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let #(changed, next_command) = type_into(editor, "updated source")

  assert changed.snippet.files
    == [snippet_model.File("main.js", "updated source")]
  assert workspace.selected_text(changed.workspace) == "updated source"
  assert contains(next_command, command.SaveDraft(draft_projection.write(changed)))
}

pub fn input_for_a_replaced_document_is_rejected_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let current = code_editor_model.active_session(editor.workspace.editor)
  let stale =
    code_editor_message.NativeInput(
      session: session.key_to_string(current.key),
      generation: current.generation + 1,
      value: "from a document that no longer exists",
      selection_anchor: 0,
      selection_head: 0,
    )

  let #(unchanged, _) =
    editor_update.update(
      editor,
      message.CodeEditor(code_editor_message.InputReceived(stale)),
      option.None,
    )

  assert unchanged.snippet.files == editor.snippet.files
}

pub fn input_for_another_session_is_rejected_test() {
  let assert model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  let other =
    code_editor_message.NativeInput(
      session: session.key_to_string(session.stdin_key()),
      generation: 0,
      value: "stdin text",
      selection_anchor: 0,
      selection_head: 0,
    )

  let #(unchanged, _) =
    editor_update.update(
      editor,
      message.CodeEditor(code_editor_message.InputReceived(other)),
      option.None,
    )

  assert unchanged.snippet.files == editor.snippet.files
}

pub fn each_file_keeps_its_own_editing_session_test() {
  let assert model.Ready(base) = editor_scenario.new_editor(language.JavaScript)
  let #(edited, _) = type_into(base, "first file")

  let with_second =
    model.Editor(
      ..edited,
      snippet: model.Snippet(
        ..edited.snippet,
        files: list.append(edited.snippet.files, [
          snippet_model.File("helper.js", ""),
        ]),
      ),
      workspace: workspace.add_file(edited.workspace, 1),
    )
  let #(second_edited, _) = type_into(with_second, "second file")

  let back =
    model.Editor(
      ..second_edited,
      workspace: workspace.select(second_edited.workspace, model.FileTab(0)),
    )

  assert workspace.selected_text(back.workspace) == "first file"
  assert code_editor_model.text_of(
      back.workspace.editor,
      workspace.key_for(back.workspace.file_sessions, model.FileTab(1)),
    )
    == option.Some("second file")
}

fn type_into(
  editor: model.Editor,
  content: String,
) -> #(model.Editor, command.Command(message.EditorMsg)) {
  let current = code_editor_model.active_session(editor.workspace.editor)
  let caret = text.width(content)
  editor_update.update(
    editor,
    message.CodeEditor(
      code_editor_message.InputReceived(code_editor_message.NativeInput(
        session: session.key_to_string(current.key),
        generation: current.generation,
        value: content,
        selection_anchor: caret,
        selection_head: caret,
      )),
    ),
    option.None,
  )
}

fn contains(
  next: command.Command(message.EditorMsg),
  wanted: command.Command(message.EditorMsg),
) -> Bool {
  case next {
    command.Batch(commands) -> list.any(commands, contains(_, wanted))
    other -> other == wanted
  }
}
