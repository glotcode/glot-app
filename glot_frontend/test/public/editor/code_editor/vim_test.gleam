//// Vim command traces, driven through the same reducer production uses.

import gleam/list
import gleam/option
import gleam/string
import glot_frontend/public/editor/code_editor/keymap/vim
import glot_frontend/public/editor/code_editor/keys.{type Key}
import glot_frontend/public/editor/code_editor/message
import glot_frontend/public/editor/code_editor/settings_bridge
import support/code_editor_driver as driver

fn vim_editor(content: String) -> driver.Driver {
  driver.with_bindings(content, settings_bridge.VimLike)
}

/// Type a Vim key sequence. Uppercase letters carry Shift, `<Esc>` is Escape,
/// and `<C-x>` is a control chord.
fn trace(editing: driver.Driver, sequence: String) -> driver.Driver {
  list.fold(tokens(sequence), editing, driver.press)
}

fn tokens(sequence: String) -> List(Key) {
  parse(string.to_graphemes(sequence), [])
}

fn parse(remaining: List(String), collected: List(Key)) -> List(Key) {
  case remaining {
    [] -> list.reverse(collected)
    ["<", ..rest] ->
      case take_until(rest, ">", "") {
        Ok(#(name, tail)) -> parse(tail, [special(name), ..collected])
        Error(_) -> parse(rest, [keys.shift("<"), ..collected])
      }
    [grapheme, ..rest] ->
      parse(rest, [
        keys.Key(
          key: grapheme,
          ctrl: False,
          alt: False,
          shift: grapheme != string.lowercase(grapheme),
          meta: False,
        ),
        ..collected
      ])
  }
}

fn take_until(
  remaining: List(String),
  terminator: String,
  collected: String,
) -> Result(#(String, List(String)), Nil) {
  case remaining {
    [] -> Error(Nil)
    [grapheme, ..rest] ->
      case grapheme == terminator {
        True -> Ok(#(collected, rest))
        False -> take_until(rest, terminator, collected <> grapheme)
      }
  }
}

fn special(name: String) -> Key {
  case name {
    "Esc" -> keys.plain("Escape")
    "CR" -> keys.plain("Enter")
    "BS" -> keys.plain("Backspace")
    "Space" -> keys.plain(" ")
    "Tab" -> keys.plain("Tab")
    _ ->
      case string.starts_with(name, "C-") {
        True -> keys.ctrl(string.drop_start(name, 2))
        False -> keys.plain(name)
      }
  }
}

// -- Modes -------------------------------------------------------------------

pub fn the_editor_starts_in_normal_mode_test() {
  let editing = vim_editor("hello")
  assert vim.mode(editing.model.vim) == vim.NormalMode
  assert !vim.accepts_native_input(editing.model.vim)
}

pub fn insert_mode_accepts_native_typing_and_escape_leaves_it_test() {
  let editing = trace(vim_editor("hello"), "i")
  assert vim.mode(editing.model.vim) == vim.InsertMode
  assert vim.accepts_native_input(editing.model.vim)

  let back = trace(editing, "<Esc>")
  assert vim.mode(back.model.vim) == vim.NormalMode
}

pub fn a_appends_after_the_caret_test() {
  let editing = trace(vim_editor("ab"), "a")
  assert driver.caret(editing) == 1
}

pub fn shift_a_moves_to_the_end_of_the_line_test() {
  let editing = trace(vim_editor("abc\ndef"), "A")
  assert driver.caret(editing) == 3
}

pub fn o_opens_a_line_below_test() {
  let editing = trace(vim_editor("one\ntwo"), "o")
  assert driver.text_of(editing) == "one\n\ntwo"
  assert vim.mode(editing.model.vim) == vim.InsertMode
}

// -- Motions -----------------------------------------------------------------

pub fn word_motions_move_by_word_test() {
  let editing = trace(vim_editor("alpha beta gamma"), "w")
  assert driver.caret(editing) == 6

  let further = trace(editing, "w")
  assert driver.caret(further) == 11

  let back = trace(further, "b")
  assert driver.caret(back) == 6
}

pub fn counts_multiply_a_motion_test() {
  let editing = trace(vim_editor("alpha beta gamma delta"), "3w")
  assert driver.caret(editing) == 17
}

pub fn dollar_and_caret_move_within_the_line_test() {
  let editing = trace(vim_editor("  spaced out"), "$")
  assert driver.caret(editing) == 12

  let first = trace(editing, "^")
  assert driver.caret(first) == 2
}

pub fn gg_and_shift_g_move_between_document_edges_test() {
  let editing = trace(vim_editor("one\ntwo\nthree"), "G")
  assert driver.caret(editing) == 8

  let top = trace(editing, "gg")
  assert driver.caret(top) == 0
}

pub fn find_character_motions_work_and_repeat_test() {
  let editing = trace(vim_editor("a.b.c"), "f.")
  assert driver.caret(editing) == 1

  let repeated = trace(editing, ";")
  assert driver.caret(repeated) == 3
}

pub fn percent_jumps_to_the_matching_bracket_test() {
  let editing = trace(vim_editor("(abc)"), "%")
  assert driver.caret(editing) == 4
}

// -- Operators ---------------------------------------------------------------

pub fn dw_deletes_a_word_test() {
  let editing = trace(vim_editor("alpha beta"), "dw")
  assert driver.text_of(editing) == "beta"
}

pub fn dd_deletes_the_line_test() {
  let editing = trace(vim_editor("one\ntwo\nthree"), "dd")
  assert driver.text_of(editing) == "two\nthree"
}

pub fn a_count_applies_to_a_linewise_operator_test() {
  let editing = trace(vim_editor("one\ntwo\nthree\nfour"), "2dd")
  assert driver.text_of(editing) == "three\nfour"
}

pub fn cw_changes_a_word_and_enters_insert_mode_test() {
  let editing = trace(vim_editor("alpha beta"), "cw")
  // `cw` behaves like `ce`: the space after the word survives.
  assert driver.text_of(editing) == " beta"
  assert vim.mode(editing.model.vim) == vim.InsertMode
}

pub fn x_deletes_the_character_under_the_caret_test() {
  let editing = trace(vim_editor("abc"), "x")
  assert driver.text_of(editing) == "bc"
}

pub fn shift_d_deletes_to_the_end_of_the_line_test() {
  let editing =
    vim_editor("keep this away")
    |> driver.place_caret(5)
    |> trace("D")

  assert driver.text_of(editing) == "keep "
}

pub fn indent_operators_shift_lines_test() {
  let editing = trace(vim_editor("one\ntwo"), ">>")
  assert driver.text_of(editing) == "  one\ntwo"

  let back = trace(editing, "<<")
  assert driver.text_of(back) == "one\ntwo"
}

pub fn case_operators_change_a_word_test() {
  let upper = trace(vim_editor("alpha beta"), "gUw")
  assert driver.text_of(upper) == "ALPHA beta"

  let lower = trace(upper, "guw")
  assert driver.text_of(lower) == "alpha beta"
}

pub fn gc_toggles_a_comment_test() {
  let editing = trace(vim_editor("const a = 1"), "gcc")
  assert driver.text_of(editing) == "// const a = 1"
}

// -- Text objects ------------------------------------------------------------

pub fn diw_deletes_the_word_under_the_caret_test() {
  let editing =
    vim_editor("alpha beta gamma")
    |> driver.place_caret(7)
    |> trace("diw")

  assert driver.text_of(editing) == "alpha  gamma"
}

pub fn di_paren_deletes_inside_brackets_test() {
  let editing =
    vim_editor("call(one, two)")
    |> driver.place_caret(7)
    |> trace("di(")

  assert driver.text_of(editing) == "call()"
}

pub fn da_quote_deletes_the_quoted_string_test() {
  let editing =
    vim_editor("x = \"value\";")
    |> driver.place_caret(6)
    |> trace("da\"")

  assert driver.text_of(editing) == "x = ;"
}

// -- Registers, paste, repeat, macros ---------------------------------------

pub fn yank_and_paste_round_trip_through_the_register_test() {
  let editing = trace(vim_editor("one\ntwo"), "yyp")
  assert driver.text_of(editing) == "one\none\ntwo"
}

pub fn a_named_register_keeps_its_own_text_test() {
  let editing =
    vim_editor("alpha\nbeta")
    |> trace("\"ayy")
    |> trace("j")
    |> trace("\"ap")

  assert driver.text_of(editing) == "alpha\nbeta\nalpha"
}

pub fn dot_repeats_the_last_edit_test() {
  let editing = trace(vim_editor("one two three"), "dw.")
  assert driver.text_of(editing) == "three"
}

pub fn a_macro_records_and_replays_test() {
  let editing =
    vim_editor("a\nb\nc")
    |> trace("qqxjq")
    |> trace("@q")

  assert driver.text_of(editing) == "\n\nc"
}

pub fn marks_can_be_set_and_jumped_to_test() {
  let editing =
    vim_editor("one\ntwo\nthree")
    |> trace("jma")
    |> trace("gg")
    |> trace("`a")

  assert driver.caret(editing) == 4
}

// -- Visual mode -------------------------------------------------------------

pub fn visual_mode_selects_and_deletes_test() {
  let editing = trace(vim_editor("alpha beta"), "vlld")
  assert driver.text_of(editing) == "ha beta"
}

pub fn visual_line_mode_deletes_whole_lines_test() {
  let editing = trace(vim_editor("one\ntwo\nthree"), "Vd")
  assert driver.text_of(editing) == "two\nthree"
}

pub fn escape_leaves_visual_mode_test() {
  let editing = trace(vim_editor("abc"), "vl<Esc>")
  assert vim.mode(editing.model.vim) == vim.NormalMode
}

// -- Increments and joins ----------------------------------------------------

pub fn control_a_increments_the_number_under_the_caret_test() {
  let editing = trace(vim_editor("count = 41"), "<C-a>")
  assert driver.text_of(editing) == "count = 42"

  let back = trace(editing, "<C-x>")
  assert driver.text_of(back) == "count = 41"
}

pub fn shift_j_joins_lines_test() {
  let editing = trace(vim_editor("one\n  two"), "J")
  assert driver.text_of(editing) == "one two"
}

// -- Undo --------------------------------------------------------------------

pub fn u_undoes_and_control_r_redoes_test() {
  let editing = trace(vim_editor("one\ntwo"), "dd")
  assert driver.text_of(editing) == "two"

  let undone = trace(editing, "u")
  assert driver.text_of(undone) == "one\ntwo"

  let redone = trace(undone, "<C-r>")
  assert driver.text_of(redone) == "two"
}

// -- Ex commands -------------------------------------------------------------

pub fn the_ex_prompt_opens_and_write_asks_the_page_to_save_test() {
  let editing = trace(vim_editor("code"), ":")
  assert editing.model.prompt != option.None

  let submitted =
    editing
    |> driver.send(message.PromptChanged("w"))
    |> driver.send(message.PromptSubmitted)

  assert list.contains(submitted.outbound, message.SaveRequested)
}

pub fn ex_substitute_replaces_across_the_document_test() {
  let editing =
    trace(vim_editor("aa bb aa"), ":")
    |> driver.send(message.PromptChanged("s/aa/zz/g"))
    |> driver.send(message.PromptSubmitted)

  assert driver.text_of(editing) == "zz bb zz"
}
