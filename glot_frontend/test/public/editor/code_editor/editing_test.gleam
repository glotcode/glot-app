//// Editing operations, Unicode boundaries, and native input reconciliation.

import gleam/list
import gleam/string
import gleam/option
import glot_core/language
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/keys
import glot_frontend/public/editor/code_editor/message
import glot_frontend/public/editor/code_editor/model
import glot_frontend/public/editor/code_editor/reconcile
import glot_frontend/public/editor/code_editor/session
import glot_frontend/public/editor/code_editor/settings_bridge
import glot_frontend/public/editor/code_editor/transaction
import support/code_editor_driver as driver

// -- Reconciliation ----------------------------------------------------------

pub fn a_typed_character_becomes_a_minimal_change_test() {
  let doc = document.from_string("const a = 1;")
  assert reconcile.diff(doc, "const ab = 1;")
    == option.Some(transaction.Change(from: 7, to: 7, insert: "b"))
}

pub fn a_deletion_becomes_a_minimal_change_test() {
  let doc = document.from_string("const ab = 1;")
  assert reconcile.diff(doc, "const a = 1;")
    == option.Some(transaction.Change(from: 7, to: 8, insert: ""))
}

pub fn an_unchanged_value_produces_no_change_test() {
  assert reconcile.diff(document.from_string("same"), "same") == option.None
}

pub fn a_multi_line_paste_becomes_one_change_test() {
  let doc = document.from_string("one\nfour")
  assert reconcile.diff(doc, "one\ntwo\nthree\nfour")
    == option.Some(transaction.Change(from: 4, to: 4, insert: "two\nthree\n"))
}

pub fn removing_lines_becomes_one_change_test() {
  let doc = document.from_string("one\ntwo\nthree")
  assert reconcile.diff(doc, "one\nthree")
    == option.Some(transaction.Change(from: 4, to: 8, insert: ""))
}

pub fn pasted_line_endings_are_normalised_test() {
  let doc = document.from_string("a")
  let assert option.Some(change) = reconcile.diff(doc, "a\r\nb")
  assert change == transaction.Change(from: 1, to: 1, insert: "\nb")
}

pub fn a_composition_replaces_the_composing_text_as_one_change_test() {
  let doc = document.from_string("hi ")
  assert reconcile.diff(doc, "hi \u{3053}\u{3093}")
    == option.Some(
      transaction.Change(from: 3, to: 3, insert: "\u{3053}\u{3093}"),
    )
}

pub fn input_while_composing_is_left_alone_until_it_ends_test() {
  let editing =
    driver.new("")
    |> driver.send(message.CompositionStarted)
    |> driver.type_text("partial")

  assert driver.text_of(editing) == ""

  let finished =
    driver.send(
      editing,
      message.CompositionEnded(message.NativeInput(
        session: session.key_to_string(session.file_key(0)),
        generation: 0,
        value: "\u{3053}\u{3093}",
        selection_anchor: 2,
        selection_head: 2,
      )),
    )

  assert driver.text_of(finished) == "\u{3053}\u{3093}"
}

pub fn the_browsers_own_undo_is_cancelled_and_routed_through_ours_test() {
  let editing =
    driver.new("start")
    |> driver.type_text("started")
    |> driver.send(message.BeforeInputReceived("historyUndo"))

  assert driver.text_of(editing) == "start"
}

// -- Unicode -----------------------------------------------------------------

pub fn movement_steps_over_whole_characters_test() {
  let editing =
    driver.new("a\u{1F600}b")
    |> driver.press(keys.plain("ArrowRight"))
    |> driver.press(keys.plain("ArrowRight"))

  assert driver.caret(editing) == 3
}

pub fn backspace_removes_a_whole_emoji_test() {
  let editing =
    driver.new("a\u{1F600}")
    |> driver.place_caret(3)
    |> driver.press(keys.plain("Backspace"))

  assert driver.text_of(editing) == "a"
}

pub fn backspace_removes_a_whole_combining_sequence_test() {
  let editing =
    driver.new("e\u{0301}")
    |> driver.place_caret(2)
    |> driver.press(keys.plain("Backspace"))

  assert driver.text_of(editing) == ""
}

pub fn vertical_movement_uses_character_columns_test() {
  let editing =
    driver.new("\u{1F600}\u{1F600}x\nabcde")
    |> driver.place_caret(5)
    |> driver.press(keys.plain("ArrowDown"))

  // Two emoji plus one letter is three characters, not five code units.
  assert driver.caret(editing) == 9
}

pub fn bidirectional_text_keeps_logical_movement_test() {
  let editing =
    driver.new("abc \u{05D0}\u{05D1}\u{05D2}")
    |> driver.place_caret(4)
    |> driver.press(keys.plain("ArrowRight"))

  assert driver.caret(editing) == 5
}

pub fn tabs_count_as_single_characters_test() {
  let editing =
    driver.new("\tx")
    |> driver.press(keys.plain("ArrowRight"))

  assert driver.caret(editing) == 1
}

// -- Line and block operations ----------------------------------------------

pub fn lines_move_and_copy_test() {
  let moved =
    driver.new("one\ntwo")
    |> driver.place_caret(5)
    |> driver.press(keys.alt("ArrowUp"))

  assert driver.text_of(moved) == "two\none"

  let copied =
    driver.new("one\ntwo")
    |> driver.press(keys.Key(
      key: "ArrowDown",
      ctrl: False,
      alt: True,
      shift: True,
      meta: False,
    ))

  assert driver.text_of(copied) == "one\none\ntwo"
}

pub fn comment_toggling_uses_the_language_test() {
  let javascript =
    driver.new("const a = 1;")
    |> driver.press(keys.ctrl("/"))

  assert driver.text_of(javascript) == "// const a = 1;"

  let uncommented = driver.press(javascript, keys.ctrl("/"))
  assert driver.text_of(uncommented) == "const a = 1;"

  let python =
    driver.start("x = 1", language.Python, settings_bridge.Plain, False)
    |> driver.press(keys.ctrl("/"))

  assert driver.text_of(python) == "# x = 1"
}

pub fn commenting_several_lines_uses_the_shallowest_indentation_test() {
  let editing =
    driver.new("  a\n    b")
    |> driver.select(0, 9)
    |> driver.press(keys.ctrl("/"))

  assert driver.text_of(editing) == "  // a\n  //   b"
}

pub fn delete_line_removes_the_whole_line_test() {
  let editing =
    driver.new("one\ntwo\nthree")
    |> driver.place_caret(5)
    |> driver.press(keys.Key(
      key: "k",
      ctrl: True,
      alt: False,
      shift: True,
      meta: False,
    ))

  assert driver.text_of(editing) == "one\nthree"
}

pub fn indent_selection_follows_the_bracket_structure_test() {
  let editing =
    driver.new("function f() {\nreturn 1;\n}")
    |> driver.select(15, 24)
    |> driver.press(keys.Key(
      key: "\\",
      ctrl: True,
      alt: True,
      shift: False,
      meta: False,
    ))

  assert driver.text_of(editing) == "function f() {\n  return 1;\n}"
}

pub fn the_matching_bracket_can_be_jumped_to_test() {
  let editing =
    driver.new("call(one)")
    |> driver.place_caret(4)
    |> driver.press(keys.Key(
      key: "\\",
      ctrl: True,
      alt: False,
      shift: True,
      meta: False,
    ))

  assert driver.caret(editing) == 8
}

// -- Sessions ----------------------------------------------------------------

pub fn each_session_keeps_its_own_history_and_caret_test() {
  let first = session.file_key(0)
  let second = session.file_key(1)

  let editing =
    driver.new("first")
    |> driver.place_caret(2)

  let with_second =
    model.open_session(editing.model, second, "second")
    |> model.activate(second)

  assert model.text(with_second) == "second"

  let back = model.activate(with_second, first)
  assert model.text(back) == "first"
}

pub fn stdin_is_never_highlighted_test() {
  let editing = driver.new("class x")
  let with_stdin =
    model.open_session(editing.model, session.stdin_key(), "class x")
    |> model.activate(session.stdin_key())
    |> model.refresh

  let assert [line] = with_stdin.rendered
  let assert [only] = line.tokens
  assert only.start == 0
  assert only.end == 7
}

fn is_document_sync(command: browser_command.Command(a)) -> Bool {
  case command {
    browser_command.SyncDocument(..) -> True
    browser_command.Batch(commands) -> list.any(commands, is_document_sync)
    _ -> False
  }
}

// -- One-frame disagreements between the view and the reducer -----------------

pub fn a_cancelled_key_the_editor_no_longer_claims_is_still_typed_test() {
  // The view cancels a key from the model it last rendered. If the mode has
  // since changed, the character must not be lost.
  let editing =
    driver.new("")
    |> driver.press_prevented(keys.plain("q"))

  assert driver.text_of(editing) == "q"
}

pub fn a_cancelled_key_the_editor_does_claim_is_not_typed_twice_test() {
  let editing =
    driver.new("word")
    |> driver.place_caret(0)
    |> driver.press(keys.plain("Tab"))

  assert driver.text_of(editing) == "  word"
}

pub fn a_key_the_browser_typed_but_the_mode_claims_is_written_back_test() {
  let editing =
    driver.with_bindings("abc", settings_bridge.VimLike)
    |> driver.press_unprevented(keys.plain("x"))

  // Vim's `x` deleted a character, and the document is pushed back over the
  // character the browser had already typed.
  assert driver.text_of(editing) == "bc"
  assert list.any(editing.commands, is_document_sync)
}

pub fn a_read_only_editor_never_types_a_cancelled_key_test() {
  let editing =
    driver.read_only("fixed")
    |> driver.press_prevented(keys.plain("q"))

  assert driver.text_of(editing) == "fixed"
}


pub fn keys_queued_during_composition_do_not_execute_commands_test() {
  let editing =
    driver.new("original")
    |> driver.send(message.CompositionStarted)
    |> driver.reset_log
    |> driver.press_prevented(keys.plain("Enter"))
    |> driver.press_prevented(keys.plain("Backspace"))
    |> driver.press_prevented(keys.ctrl("Enter"))

  assert driver.text_of(editing) == "original"
  assert editing.outbound == []
  assert !list.any(editing.commands, is_document_sync)
}


pub fn activating_a_file_refreshes_highlighting_without_an_input_event_test() {
  let first = session.file_key(0)
  let second = session.file_key(1)
  let editing = driver.new("const first = 1;")
  let switched =
    model.open_session(editing.model, second, "const second = 2;")
    |> model.activate(second)

  let assert [line] = switched.rendered
  assert line.text == "const second = 2;"

  let back = model.activate(switched, first)
  let assert [line] = back.rendered
  assert line.text == "const first = 1;"
}


pub fn long_unicode_suffix_is_reconciled_without_splitting_clusters_test() {
  let suffix = string.repeat("🦊é", 2000)
  let doc = document.from_string("a" <> suffix)
  assert reconcile.diff(doc, "ab" <> suffix)
    == option.Some(transaction.Change(from: 1, to: 1, insert: "b"))
  let assert option.Some(change) = reconcile.diff(doc, "á" <> suffix)
  assert change == transaction.Change(from: 0, to: 1, insert: "á")
  assert transaction.apply(doc, [change]) |> document.to_string == "á" <> suffix
}
