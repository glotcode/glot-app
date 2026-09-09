//// The editor command algebra.
////
//// Keymaps — default, Vim, and Emacs — all resolve keys to these commands, and
//// `dispatch` is the single place that turns a command into a transaction. That
//// is what keeps the three binding sets behaving identically for the same
//// operation, and what makes a keymap trace testable without a browser.

import glot_frontend/public/editor/code_editor/state.{type State}
import glot_frontend/public/editor/code_editor/transaction.{type Change}

pub type EditorCommand {
  CoalesceUndo(before: State)
  EditRanges(changes: List(Change), caret: Int)
  Noop

  MoveChar(forward: Bool, extend: Bool)
  MoveGroup(forward: Bool, extend: Bool)
  MoveSubword(forward: Bool, extend: Bool)
  MoveLine(forward: Bool, extend: Bool)
  MovePage(forward: Bool, extend: Bool)
  MoveLineBoundary(forward: Bool, extend: Bool)
  MoveLineEdge(forward: Bool, extend: Bool)
  MoveDocBoundary(forward: Bool, extend: Bool)
  MoveParagraph(forward: Bool, extend: Bool)
  MoveToFirstNonWhitespace(extend: Bool)
  MoveToColumn(column: Int, extend: Bool)
  MoveToLineNumber(line: Int, extend: Bool)
  MoveToMatchingBracket(extend: Bool)
  MoveToOffset(offset: Int, extend: Bool)

  DeleteChar(forward: Bool)
  DeleteGroup(forward: Bool)
  DeleteLineBoundary(forward: Bool)
  DeleteToLineEnd
  DeleteToLineStart
  DeleteLine
  DeleteSelection

  InsertText(String)
  InsertNewlineAndIndent
  InsertBlankLine
  SplitLine
  TransposeChars
  JoinLines(keep_spaces: Bool)

  IndentMore
  IndentLess
  IndentSelection
  MoveLineUp
  MoveLineDown
  CopyLineUp
  CopyLineDown

  ToggleComment
  ToggleBlockComment
  ChangeCase(to_upper: Bool)
  ChangeWordCase(to_upper: Bool)

  SelectAll
  SelectLine
  SelectWord
  SelectParagraph
  SimplifySelection
  SelectRange(from: Int, to: Int)

  Undo
  Redo
  UndoSelection
  RedoSelection

  OpenSearchPanel
  CloseSearchPanel
  FindNext
  FindPrevious
  SelectNextOccurrence
  SelectSelectionMatches
  ReplaceNext
  ReplaceAll
  SetSearchQuery(pattern: String, whole_word: Bool, regexp: Bool)
  Substitute(pattern: String, replacement: String, all: Bool)
  SortLines
  ClearMarks
  SearchForSelection(forward: Bool, whole_word: Bool)
  OpenGotoLinePrompt

  ScrollCaret(position: ScrollPosition)
  ScrollLines(forward: Bool)
  RecenterTopBottom
  CenterSelection

  Copy
  Cut
  Paste

  SetMark
  ClearMark
  ExchangePointAndMark
  KillRegion(save_only: Bool)
  KillLine
  KillWord(forward: Bool)
  Yank
  YankRotate
  KeyboardQuit
  SelectRectangularRegion
  OpenCommandPrompt(String)

  RunSnippet
  SaveSnippet

  Sequence(List(EditorCommand))
}

pub type ScrollPosition {
  ScrollTop
  ScrollCenter
  ScrollBottom
}
