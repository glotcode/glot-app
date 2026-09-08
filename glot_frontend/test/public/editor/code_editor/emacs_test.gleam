//// Emacs command traces, including the upstream bugs this editor corrects.

import gleam/option
import glot_frontend/public/editor/code_editor/keymap/emacs
import glot_frontend/public/editor/code_editor/keys
import glot_frontend/public/editor/code_editor/message
import glot_frontend/public/editor/code_editor/settings_bridge
import support/code_editor_driver as driver

fn emacs_editor(content: String) -> driver.Driver {
  driver.with_bindings(content, settings_bridge.EmacsLike)
}

fn meta(key: String) -> keys.Key {
  keys.alt(key)
}

// -- Movement ----------------------------------------------------------------

pub fn control_movement_walks_characters_and_lines_test() {
  let editing =
    emacs_editor("one\ntwo")
    |> driver.press(keys.ctrl("f"))
    |> driver.press(keys.ctrl("f"))

  assert driver.caret(editing) == 2

  // `C-n` is one of the chords the browser keeps for itself; the arrow key is
  // bound to the same command.
  let down = driver.press(editing, keys.plain("ArrowDown"))
  assert driver.caret(down) == 6

  let start = driver.press(down, keys.ctrl("a"))
  assert driver.caret(start) == 4

  let end = driver.press(start, keys.ctrl("e"))
  assert driver.caret(end) == 7
}

pub fn meta_f_and_meta_b_move_by_word_test() {
  let editing =
    emacs_editor("alpha beta")
    |> driver.press(meta("f"))

  assert driver.caret(editing) == 5

  let back = driver.press(editing, meta("b"))
  assert driver.caret(back) == 0
}

pub fn the_mark_turns_movement_into_selection_test() {
  let editing =
    emacs_editor("alpha beta")
    |> driver.press(keys.ctrl(" "))
    |> driver.press(meta("f"))

  assert emacs.mark(editing.model.emacs) == option.Some(0)
  assert driver.selected(editing) == "alpha"
}

pub fn control_g_clears_the_mark_test() {
  let editing =
    emacs_editor("alpha")
    |> driver.press(keys.ctrl(" "))
    |> driver.press(keys.ctrl("g"))

  assert emacs.mark(editing.model.emacs) == option.None
}

// -- Kill ring ---------------------------------------------------------------

pub fn control_k_kills_to_the_end_of_the_line_and_control_y_yanks_test() {
  let editing =
    emacs_editor("keep this\nnext")
    |> driver.place_caret(4)
    |> driver.press(keys.ctrl("k"))

  assert driver.text_of(editing) == "keep\nnext"

  let yanked =
    editing
    |> driver.place_caret(9)
    |> driver.press(keys.ctrl("y"))

  assert driver.text_of(yanked) == "keep\nnext this"
}

pub fn killing_the_region_removes_it_and_saving_it_does_not_test() {
  // `C-w` closes the browser tab and cannot be cancelled, so the command is
  // reached through `M-x`.
  let killed =
    emacs_editor("alpha beta")
    |> driver.press(keys.ctrl(" "))
    |> driver.press(meta("f"))
    |> driver.press(meta("x"))
    |> driver.send(message.PromptChanged("kill-region"))
    |> driver.send(message.PromptSubmitted)

  assert driver.text_of(killed) == " beta"

  let copied =
    emacs_editor("alpha beta")
    |> driver.press(keys.ctrl(" "))
    |> driver.press(meta("f"))
    |> driver.press(meta("w"))

  assert driver.text_of(copied) == "alpha beta"
}

pub fn meta_y_rotates_through_the_kill_ring_test() {
  let editing =
    emacs_editor("first\nsecond")
    |> driver.place_caret(0)
    |> driver.press(keys.ctrl("k"))
    |> driver.place_caret(1)
    |> driver.press(keys.ctrl("k"))

  // The most recent kill comes back first, then the one before it.
  let yanked = driver.press(editing, keys.ctrl("y"))
  assert driver.text_of(yanked) == "\nsecond"

  let rotated = driver.press(yanked, meta("y"))
  assert driver.text_of(rotated) == "\nfirst"
}

pub fn meta_d_kills_the_word_after_point_test() {
  let editing =
    emacs_editor("alpha beta")
    |> driver.press(meta("d"))

  assert driver.text_of(editing) == " beta"
}

// -- Editing -----------------------------------------------------------------

pub fn transpose_chars_swaps_around_the_caret_test() {
  // `C-t` opens a browser tab and cannot be cancelled, so the command is
  // reached through `M-x` instead.
  let editing =
    emacs_editor("ab")
    |> driver.place_caret(1)
    |> driver.press(meta("x"))
    |> driver.send(message.PromptChanged("transpose-chars"))
    |> driver.send(message.PromptSubmitted)

  assert driver.text_of(editing) == "ba"
}

pub fn chords_the_browser_owns_are_left_alone_test() {
  let editing =
    emacs_editor("ab")
    |> driver.place_caret(1)
    |> driver.press(keys.ctrl("t"))
    |> driver.press(keys.ctrl("w"))
    |> driver.press(keys.ctrl("n"))

  assert driver.text_of(editing) == "ab"
}

pub fn control_o_splits_the_line_without_moving_the_caret_test() {
  let editing =
    emacs_editor("abcd")
    |> driver.place_caret(2)
    |> driver.press(keys.ctrl("o"))

  assert driver.text_of(editing) == "ab\ncd"
  assert driver.caret(editing) == 2
}

pub fn meta_semicolon_toggles_a_comment_test() {
  let editing =
    emacs_editor("const a = 1")
    |> driver.press(meta(";"))

  assert driver.text_of(editing) == "// const a = 1"
}

pub fn meta_u_and_meta_l_change_word_case_test() {
  let upper =
    emacs_editor("alpha beta")
    |> driver.press(meta("u"))

  assert driver.text_of(upper) == "ALPHA beta"

  // Point has moved past the word, so the next command acts on the next word.
  let lower = driver.press(upper, meta("l"))
  assert driver.text_of(lower) == "ALPHA beta"
}

// -- Prefixes and prompts ----------------------------------------------------

pub fn the_control_x_prefix_is_announced_and_then_completed_test() {
  let prefixed =
    emacs_editor("alpha")
    |> driver.press(keys.ctrl("x"))

  assert prefixed.model.status == option.Some("C-x-")

  let selected = driver.press(prefixed, keys.ctrl("p"))
  assert driver.selected(selected) == "alpha"
}

pub fn control_x_control_x_exchanges_point_and_mark_test() {
  let editing =
    emacs_editor("alpha beta")
    |> driver.press(keys.ctrl(" "))
    |> driver.press(meta("f"))
    |> driver.press(keys.ctrl("x"))
    |> driver.press(keys.ctrl("x"))

  assert driver.caret(editing) == 0
}

pub fn the_universal_argument_repeats_a_command_test() {
  let editing =
    emacs_editor("abcdef")
    |> driver.press(keys.ctrl("u"))
    |> driver.press(keys.plain("3"))
    |> driver.press(keys.ctrl("f"))

  assert driver.caret(editing) == 3
}

pub fn meta_x_opens_the_command_prompt_test() {
  let editing =
    emacs_editor("alpha")
    |> driver.press(meta("x"))

  assert editing.model.prompt != option.None

  let ran =
    editing
    |> driver.send(message.PromptChanged("mark-whole-buffer"))
    |> driver.send(message.PromptSubmitted)

  assert driver.selected(ran) == "alpha"
}

// -- Corrected upstream bugs -------------------------------------------------

pub fn page_up_selects_upwards_when_the_mark_is_set_test() {
  let editing =
    emacs_editor("a\nb\nc\nd\ne")
    |> driver.place_caret(8)
    |> driver.press(keys.ctrl(" "))
    |> driver.press(meta("v"))

  // Upstream bound the selecting branch of this key to `selectPageDown`.
  assert driver.caret(editing) <= 8
  assert driver.anchor(editing) == 8
}

pub fn control_x_control_l_downcases_the_region_test() {
  let editing =
    emacs_editor("ALPHA beta")
    |> driver.press(keys.ctrl(" "))
    |> driver.press(meta("f"))
    |> driver.press(keys.ctrl("x"))
    |> driver.press(keys.ctrl("l"))

  // Upstream mapped this to upcase, duplicating `C-x C-u`.
  assert driver.text_of(editing) == "alpha beta"
}

pub fn meta_at_marks_the_word_after_point_test() {
  let editing =
    emacs_editor("alpha beta")
    |> driver.press(meta("@"))

  // Upstream registered `markWord` as an empty function.
  assert driver.selected(editing) == "alpha"
}

pub fn meta_slash_is_unbound_because_glot_has_no_autocomplete_test() {
  let editing =
    emacs_editor("alpha")
    |> driver.press(meta("/"))

  assert driver.text_of(editing) == "alpha"
  assert editing.outbound == []
}
