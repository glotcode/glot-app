//// Browser work the editor asks for, as data.
////
//// Nothing here executes anything; `interpreter` turns these into effects at
//// the production boundary, and tests interpret them as values.

import gleam/list

pub type ScrollIntent {
  KeepCaretVisible
  CaretToTop
  CaretToCenter
  CaretToBottom
}

pub type Command(msg) {
  None
  Batch(List(Command(msg)))
  /// Write the document and selection back into the textarea.
  SyncDocument(value: String, selection_anchor: Int, selection_head: Int)
  /// Write only the selection back into the textarea.
  SyncSelection(selection_anchor: Int, selection_head: Int)
  /// Scroll the textarea so that `line` is visible with the given intent.
  ScrollToLine(line: Int, intent: ScrollIntent)
  /// Restore a session viewport independently of its caret position.
  SyncSession(
    session_key: String,
    generation: Int,
    value: String,
    selection_anchor: Int,
    selection_head: Int,
    scroll_top: Int,
    scroll_left: Int,
  )
  ScrollBy(lines: Int)
  FocusEditor
  FocusSearchField
  FocusPrompt
  /// Hand focus to the next or previous focusable element on the page. Tab
  /// focus mode moves focus from the reducer rather than by letting the key
  /// through, so the behaviour cannot depend on when the last render happened.
  MoveFocus(forward: Bool)
  WriteClipboard(String)
  /// Ask for fresh geometry after a resize or a font change.
  Measure(fn(Int, Int, Int, Int) -> msg)
}

pub fn none() -> Command(msg) {
  None
}

pub fn batch(commands: List(Command(msg))) -> Command(msg) {
  case list.filter(commands, fn(item) { item != None }) {
    [] -> None
    [single] -> single
    many -> Batch(many)
  }
}

pub fn map(command: Command(a), transform: fn(a) -> b) -> Command(b) {
  case command {
    None -> None
    Batch(commands) ->
      Batch(list.map(commands, fn(item) { map(item, transform) }))
    SyncDocument(value, start, end) -> SyncDocument(value, start, end)
    SyncSelection(start, end) -> SyncSelection(start, end)
    ScrollToLine(line, intent) -> ScrollToLine(line, intent)
    SyncSession(key, generation, value, anchor, head, top, left) ->
      SyncSession(key, generation, value, anchor, head, top, left)
    ScrollBy(lines) -> ScrollBy(lines)
    FocusEditor -> FocusEditor
    FocusSearchField -> FocusSearchField
    FocusPrompt -> FocusPrompt
    MoveFocus(forward) -> MoveFocus(forward)
    WriteClipboard(value) -> WriteClipboard(value)
    Measure(callback) ->
      Measure(fn(a, b, c, d) { transform(callback(a, b, c, d)) })
  }
}
