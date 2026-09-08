//// Editor messages.
////
//// Every message that originates in the browser carries the session key and
//// document generation the DOM was rendered with, so a callback that was queued
//// before a document replacement can be recognised and dropped.

import glot_frontend/public/editor/code_editor/keys.{type Key}

/// What the textarea looked like when an input event fired.
/// Anchor and head preserve the browser selection direction in UTF-16 offsets.
pub type NativeInput {
  NativeInput(
    session: String,
    generation: Int,
    value: String,
    selection_anchor: Int,
    selection_head: Int,
  )
}

pub type SelectionSnapshot {
  SelectionSnapshot(
    session: String,
    generation: Int,
    selection_anchor: Int,
    selection_head: Int,
  )
}

pub type ScrollSnapshot {
  ScrollSnapshot(session: String, scroll_top: Int, scroll_left: Int)
}

pub type SearchField {
  SearchTerm
  ReplacementTerm
}

pub type SearchToggle {
  CaseSensitive
  WholeWord
  RegularExpression
}

pub type Msg {
  /// `prevented` is the decision the view made when the key was pressed, taken
  /// from the model as it was last rendered. The reducer sees the live model,
  /// and the two can disagree by one frame when several keys arrive before a
  /// render; carrying the decision lets the reducer put that right instead of
  /// silently dropping or duplicating a character.
  KeyPressed(key: Key, prevented: Bool)
  BeforeInputReceived(String)
  InputReceived(NativeInput)
  CompositionStarted
  CompositionEnded(NativeInput)
  SelectionMoved(SelectionSnapshot)
  Scrolled(ScrollSnapshot)
  Measured(line_height: Int, height: Int, width: Int, char_width: Int)
  FocusChanged(Bool)
  Pasted(NativeInput)

  SearchFieldChanged(SearchField, String)
  SearchToggled(SearchToggle)
  SearchNextClicked
  SearchPreviousClicked
  SearchReplaceClicked(all: Bool)
  SearchClosed

  PromptChanged(String)
  PromptSubmitted
  PromptCancelled

  GutterLineClicked(Int)
}

/// Things the editor page needs to know about.
pub type Outbound {
  DocumentChanged
  RunRequested
  SaveRequested
}
