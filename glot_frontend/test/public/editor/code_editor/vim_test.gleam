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
  assert driver.caret(editing) == 11

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

  assert driver.text_of(editing) == "x =;"
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

// Compared with `vim -Nu NONE -n -es` (Vim 9.1, selection=inclusive).
pub fn switching_visual_kind_keeps_the_original_anchor_test() {
  let editing = trace(vim_editor("one\ntwo\nthree"), "vjVd")
  assert driver.text_of(editing) == "three"
}

pub fn visual_o_swaps_both_selection_endpoints_test() {
  let editing = trace(vim_editor("abcdef"), "lvlohd")
  assert driver.text_of(editing) == "def"
  assert driver.caret(editing) == 0
}

pub fn visual_x_deletes_the_inclusive_selection_test() {
  let editing = trace(vim_editor("abcdef"), "lvlx")
  assert driver.text_of(editing) == "adef"
  assert driver.caret(editing) == 1
  assert vim.mode(editing.model.vim) == vim.NormalMode
}

pub fn visual_s_changes_the_inclusive_selection_test() {
  let editing = trace(vim_editor("abcdef"), "lvls")
  assert driver.text_of(editing) == "adef"
  assert driver.caret(editing) == 1
  assert vim.mode(editing.model.vim) == vim.InsertMode
}

pub fn visual_case_changes_the_selection_and_leaves_visual_mode_test() {
  let editing = trace(vim_editor("aBcDef"), "lvl~")
  assert driver.text_of(editing) == "abCDef"
  assert driver.caret(editing) == 1
  assert vim.mode(editing.model.vim) == vim.NormalMode
}

pub fn character_delete_keeps_its_column_test() {
  let editing = trace(vim_editor("abcdef"), "llx")
  assert driver.text_of(editing) == "abdef"
  assert driver.caret(editing) == 2
}

pub fn visual_line_on_empty_line_does_not_delete_the_following_line_test() {
  let editing = trace(vim_editor("one\n\nthree"), "jVd")
  assert driver.text_of(editing) == "one\nthree"
}

pub fn escape_cancels_pending_operator_test() {
  let editing = trace(vim_editor("abcdef"), "d<Esc>llx")
  assert driver.text_of(editing) == "abdef"
  assert driver.caret(editing) == 2
}

pub fn case_operator_preserves_the_yanked_register_test() {
  let editing = trace(vim_editor("one\ntwo"), "yyjgUwp")
  assert driver.text_of(editing) == "one\nTWO\none"
}

pub fn normal_horizontal_motions_stay_on_their_line_test() {
  assert driver.caret(trace(vim_editor("abc\ndef"), "9l")) == 2
  assert driver.caret(trace(vim_editor("abc\ndef"), "jh")) == 4
}

pub fn dollar_delete_keeps_the_next_line_and_a_character_cursor_test() {
  let editing = trace(vim_editor("abc\ndef"), "ld$")
  assert driver.text_of(editing) == "a\ndef"
  assert driver.caret(editing) == 0
}

pub fn counted_replace_replaces_each_character_and_refuses_short_lines_test() {
  let editing = trace(vim_editor("abcdef"), "l3rX")
  assert driver.text_of(editing) == "aXXXef"
  assert driver.caret(editing) == 3
  assert driver.text_of(trace(vim_editor("abc\ndef"), "l3rX")) == "abc\ndef"
}

pub fn gv_restores_visual_kind_and_both_endpoints_test() {
  assert driver.text_of(trace(vim_editor("abcdef"), "lvl<Esc>lgvd")) == "adef"
  assert driver.text_of(trace(vim_editor("one\ntwo\nthree"), "Vj<Esc>gggvd"))
    == "three"
  assert driver.text_of(trace(vim_editor("abcdef"), "3lvhh<Esc>gvd")) == "aef"
}

pub fn visual_objects_select_the_object_before_the_operator_test() {
  assert driver.text_of(trace(vim_editor("alpha beta"), "viwd")) == " beta"
  assert driver.text_of(trace(vim_editor("(abc) xyz"), "lvi(d")) == "() xyz"
}

pub fn visual_replace_covers_each_character_and_preserves_line_breaks_test() {
  assert driver.text_of(trace(vim_editor("abcdef"), "lvlrX")) == "aXXdef"
  assert driver.text_of(trace(vim_editor("abc\ndef\nghi"), "VjrX"))
    == "XXX\nXXX\nghi"
}

pub fn visual_character_paste_replaces_the_selected_text_test() {
  let editing = trace(vim_editor("one two"), "yiwwvep")
  assert driver.text_of(editing) == "one one"
  assert driver.caret(editing) == 6
  assert vim.mode(editing.model.vim) == vim.NormalMode
}

pub fn explicit_one_g_goes_to_first_line_test() {
  assert driver.caret(trace(vim_editor("one\ntwo\nthree"), "G1G")) == 0
}

pub fn till_repetition_skips_adjacent_match_only_if_it_would_not_move_test() {
  assert driver.caret(trace(vim_editor("a.b.c.d"), "t.;")) == 2
  assert driver.caret(trace(vim_editor("a.b.c.d"), "t.2;")) == 2
  assert driver.caret(trace(vim_editor("a.b.c.d"), "$T.;")) == 4
}

pub fn displayed_visual_endpoints_do_not_replace_the_logical_cursor_test() {
  let editing = trace(vim_editor("abcdef"), "lvl")
  // A select/keyup callback echoes the half-open browser range.
  let echoed = driver.select(editing, 1, 3)
  assert driver.caret(echoed) == 2
  assert vim.mode(echoed.model.vim) == vim.VisualMode(vim.CharacterWise)
  assert driver.text_of(trace(echoed, "d")) == "adef"
}

pub fn pointer_selection_exits_visual_and_retains_gv_test() {
  let editing = trace(vim_editor("abcdef"), "lvl")
  let clicked = driver.place_caret(editing, 4)
  assert vim.mode(clicked.model.vim) == vim.NormalMode
  assert driver.text_of(trace(clicked, "gvd")) == "adef"
}

pub fn around_quote_includes_trailing_or_leading_whitespace_test() {
  assert driver.text_of(trace(vim_editor("a \"bc\"  d"), "2lda\"")) == "a d"
  assert driver.text_of(trace(vim_editor("a  \"bc\"d"), "3lda\"")) == "ad"
  assert driver.text_of(trace(vim_editor("a  \"bc\"  d"), "3ldi\""))
    == "a  \"\"  d"
}

pub fn block_delete_changes_only_the_rectangle_and_undoes_once_test() {
  let editing = trace(vim_editor("abcd\nefgh\nijkl"), "<C-v>jld")
  assert driver.text_of(editing) == "cd\ngh\nijkl"
  let undone = trace(editing, "u")
  assert driver.text_of(undone) == "abcd\nefgh\nijkl"
  assert driver.caret(undone) == 0
}

pub fn block_yank_paste_keeps_rows_and_can_extend_the_document_test() {
  let editing = trace(vim_editor("abcd\nefgh"), "<C-v>jlyGp")
  assert driver.text_of(editing) == "abcd\neabfgh\n ef"
}

pub fn counted_put_preserves_register_and_undo_cursor_test() {
  let put = trace(vim_editor("one two"), "yiww3p")
  assert driver.text_of(put) == "one toneoneonewo"
  assert driver.caret(put) == 13
  let undone = trace(put, "u")
  assert driver.text_of(undone) == "one two"
  assert driver.caret(undone) == 4
  assert driver.text_of(trace(undone, "\"0p")) == "one tonewo"
}

pub fn counted_line_put_is_one_undo_step_test() {
  let put = trace(vim_editor("one\ntwo"), "yy2p")
  assert driver.text_of(put) == "one\none\none\ntwo"
  assert driver.caret(put) == 4
  let undone = trace(put, "u")
  assert driver.text_of(undone) == "one\ntwo"
  assert driver.caret(undone) == 0
}

pub fn counted_block_put_pads_between_copies_and_before_existing_text_test() {
  assert driver.text_of(trace(vim_editor("abcd\nx\nijkl"), "<C-v>jlyj2p"))
    == "abcd\nxabab\nix x jkl"
  assert driver.text_of(trace(vim_editor("abcd\nx\nijkl"), "<C-v>jlyG$2p"))
    == "abcd\nx\nijklabab\n    x x"
}

pub fn block_vertical_motion_remembers_column_across_short_lines_test() {
  let editing = trace(vim_editor("abcd\nx\nijkl"), "2l<C-v>jjld")
  assert driver.text_of(editing) == "ab\nx\nij"
}

pub fn block_dollar_tracks_each_row_end_through_vertical_motion_test() {
  assert driver.text_of(trace(vim_editor("abcd\nefghijkl\nxyzxyz"), "l<C-v>$jjd"))
    == "a\ne\nx"
  assert driver.text_of(trace(vim_editor("abcd\nx\nijklmnop"), "2l<C-v>$jjd"))
    == "ab\nx\nij"
}

pub fn block_dollar_dot_retains_end_of_line_intent_test() {
  assert driver.text_of(trace(vim_editor("abcd\nefgh\nxyzxyzxyzxyz\n123456789012"), "l<C-v>$jdj."))
    == "a\n\n\n123456789012"
}

pub fn block_dollar_append_uses_each_rows_own_end_test() {
  let inserted = vim_editor("abcd\nefghijkl\nxyzxyz")
    |> trace("l<C-v>$jA") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(inserted) == "abcdX\nefghijklX\nxyzxyz"
  assert driver.text_of(trace(inserted, "u")) == "abcd\nefghijkl\nxyzxyz"
}

pub fn block_case_and_replacement_do_not_touch_surrounding_text_test() {
  assert driver.text_of(trace(vim_editor("abcd\nefgh"), "<C-v>jlU"))
    == "ABcd\nEFgh"
  assert driver.text_of(trace(vim_editor("abcd\nefgh"), "<C-v>jlrX"))
    == "XXcd\nXXgh"
}

pub fn block_delete_splits_tabs_at_screen_columns_test() {
  let editing = trace(vim_editor("abcd\n\txyz"), "l<C-v>jld")
  assert driver.text_of(editing) == "a\n yz"
}

pub fn block_shift_preserves_screen_width_and_undo_cursor_test() {
  let shifted = trace(vim_editor("abcd\na\tb\nzzzz"), "2l<C-v>j>")
  assert driver.text_of(shifted) == "a  bcd\na     b\nzzzz"
  assert driver.caret(shifted) == 1
  let undone = trace(shifted, "u")
  assert driver.text_of(undone) == "abcd\na\tb\nzzzz"
  assert driver.caret(undone) == 1
}

pub fn block_shift_includes_row_end_but_skips_shorter_rows_test() {
  assert driver.text_of(trace(vim_editor("abc\nx\nxyz"), "l<C-v>j>"))
    == "a  bc\nx  \nxyz"
  assert driver.text_of(trace(vim_editor("abcd\n\nx\nijkl"), "2l<C-v>3j>"))
    == "ab  cd\n\nx\nij  kl"
}

pub fn counted_block_shift_stops_removing_spaces_at_text_test() {
  assert driver.text_of(trace(vim_editor("a b  c\nd e  f"), "l<C-v>j2<"))
    == "ab  c\nde  f"
  assert driver.text_of(trace(vim_editor("abcd\nefgh"), "l<C-v>j2>"))
    == "a    bcd\ne    fgh"
}

pub fn native_insert_is_repeated_by_dot_and_undo_is_separate_test() {
  let inserted = vim_editor("abc") |> trace("i") |> driver.type_at_selection("XY") |> trace("<Esc>")
  let repeated = trace(inserted, "l.")
  assert driver.text_of(repeated) == "XYXYabc"
  assert driver.text_of(trace(repeated, "u")) == "XYabc"
}

pub fn change_and_insert_are_one_undo_step_test() {
  let changed = vim_editor("one two") |> trace("cw") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(changed) == "X two"
  assert driver.text_of(trace(changed, "u")) == "one two"
}

pub fn block_insertion_replicates_at_escape_and_undoes_once_test() {
  let inserted = vim_editor("abcd\nefgh") |> trace("<C-v>jlI") |> driver.type_at_selection("XY")
  assert driver.text_of(inserted) == "XYabcd\nefgh"
  let finished = trace(inserted, "<Esc>")
  assert driver.text_of(finished) == "XYabcd\nXYefgh"
  let undone = trace(finished, "u")
  assert driver.text_of(undone) == "abcd\nefgh"
  assert driver.caret(undone) == 0
}

pub fn block_append_pads_short_rows_but_change_skips_them_test() {
  let appended = vim_editor("abcd\nx\nijkl") |> trace("2l<C-v>jjA") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(appended) == "abcXd\nx  X\nijkXl"
  let changed = vim_editor("abcd\nx\nijkl") |> trace("2l<C-v>jjc") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(changed) == "abXd\nx\nijXl"
}

pub fn macro_replays_native_edits_and_escape_test() {
  let recorded = vim_editor("abc") |> trace("qqi") |> driver.type_at_selection("X") |> trace("<Esc>lq")
  let replayed = trace(recorded, "@q")
  assert driver.text_of(replayed) == "XXabc"
  assert vim.mode(replayed.model.vim) == vim.NormalMode
}

pub fn recursive_macro_obeys_a_shared_replay_limit_test() {
  let editing = trace(vim_editor("abc"), "qq@qq@q")
  assert driver.text_of(editing) == "abc"
  assert vim.mode(editing.model.vim) == vim.NormalMode
}

pub fn stale_view_insert_fallback_is_recorded_for_dot_test() {
  let inserted = vim_editor("abc") |> trace("i") |> driver.press_prevented(keys.plain("X")) |> trace("<Esc>")
  assert driver.text_of(trace(inserted, "l.")) == "XXabc"
}

pub fn stray_native_edit_after_normal_command_is_discarded_test() {
  let editing = vim_editor("abc") |> trace("i") |> driver.type_at_selection("X") |> trace("<Esc>l.")
  let stray = driver.type_at_selection(editing, ".")
  assert driver.text_of(stray) == "XXabc"
}


pub fn visual_uppercase_delete_and_change_use_whole_lines_test() {
  assert driver.text_of(trace(vim_editor("abcd\nefgh\nijkl"), "lvjD")) == "ijkl"
  let changed = vim_editor("abcd\nefgh\nijkl") |> trace("lvjC") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(changed) == "X\nijkl"
  let undone = trace(changed, "u")
  assert driver.text_of(undone) == "abcd\nefgh\nijkl"
  assert driver.caret(undone) == 5
}

pub fn block_uppercase_delete_and_change_extend_each_row_test() {
  assert driver.text_of(trace(vim_editor("abcd\nefghij\nkl"), "l<C-v>jD")) == "a\ne\nkl"
  let changed = vim_editor("abcd\n\txyz") |> trace("l<C-v>jlC") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(changed) == "aX\n X"
  assert driver.text_of(trace(changed, "u")) == "abcd\n\txyz"
}

pub fn visual_uppercase_corner_exchange_preserves_rectangle_test() {
  let editing = trace(vim_editor("abcd\nefgh"), "<C-v>jlO")
  assert driver.caret(editing) == 5
  assert driver.anchor(editing) == 1
  assert driver.text_of(trace(editing, "d")) == "cd\ngh"
  assert driver.text_of(trace(vim_editor("abcdef"), "lvllOhd")) == "ef"
}


pub fn visual_delete_repeat_retains_width_and_is_undoable_test() {
  let edited = vim_editor("abcdef") |> trace("vldl.")
  assert driver.text_of(edited) == "cf"
  assert driver.caret(edited) == 1
  assert driver.text_of(trace(edited, "u")) == "cdef"
}

pub fn block_change_repeat_retains_both_dimensions_test() {
  let edited = vim_editor("abcd\nefgh\nijkl\nmnop") |> trace("<C-v>jlc") |> driver.type_at_selection("X") |> trace("<Esc>jj.")
  assert driver.text_of(edited) == "Xcd\nXgh\nXkl\nXop"
  assert driver.caret(edited) == 8
  assert driver.text_of(trace(edited, "u")) == "Xcd\nXgh\nijkl\nmnop"
}

pub fn visual_repeat_uses_multiline_extent_test() {
  let edited = vim_editor("abcd\nefgh\nijkl\nmnop") |> trace("lvjdj0.")
  assert driver.text_of(edited) == "agh\nop"
}


pub fn counted_native_insertion_groups_undo_and_repeats_test() {
  let inserted = vim_editor("abc") |> trace("3i") |> driver.type_at_selection("XY") |> trace("<Esc>")
  assert driver.text_of(inserted) == "XYXYXYabc"
  assert driver.caret(inserted) == 5
  assert driver.text_of(trace(inserted, "u")) == "abc"
  assert driver.text_of(trace(inserted, "l.")) == "XYXYXYXYXYXYabc"
}

pub fn replace_native_text_and_backspace_restore_overwritten_characters_test() {
  let replaced = vim_editor("abcdef") |> trace("lR") |> driver.type_at_selection("XY") |> trace("<BS><Esc>")
  assert driver.text_of(replaced) == "aXcdef"
  assert driver.caret(replaced) == 1
  assert driver.text_of(trace(replaced, "u")) == "abcdef"
}

pub fn native_repeat_anchors_identical_characters_at_the_cursor_test() {
  let inserted = vim_editor("aaaa") |> trace("3i") |> driver.type_at_selection("a") |> trace("<Esc>")
  assert driver.text_of(inserted) == "aaaaaaa"
  assert driver.caret(inserted) == 2
  let replaced = vim_editor("abaa") |> trace("R") |> driver.type_at_selection("a") |> trace("<Esc>l.")
  assert driver.text_of(replaced) == "aaaa"
}

pub fn replace_repeat_stops_at_line_end_test() {
  let replaced = vim_editor("abcdef\nx\nzz") |> trace("lR") |> driver.type_at_selection("XY") |> trace("<Esc>j0.")
  assert driver.text_of(replaced) == "aXYdef\nXY\nzz"
}


pub fn empty_line_delete_preserves_yank_and_line_break_test() {
  let edited = vim_editor("one\n\nthree") |> trace("yiwjx\"0p")
  assert driver.text_of(edited) == "one\none\nthree"
  assert driver.caret(edited) == 6
}

pub fn counted_word_objects_keep_operator_state_and_whitespace_rules_test() {
  assert driver.text_of(vim_editor("one two three four") |> trace("d3iw")) == " three four"
  assert driver.text_of(vim_editor("one two three four") |> trace("2d2iw")) == "three four"
  assert driver.text_of(vim_editor("one  two three") |> trace("3ldaw")) == "one three"
  let failed = vim_editor("one two") |> trace("c9iw")
  assert driver.text_of(failed) == "one two"
  assert driver.caret(failed) == 6
  assert driver.text_of(trace(failed, "x")) == "one tw"
}

pub fn visual_word_objects_extend_in_both_directions_test() {
  assert driver.text_of(vim_editor("one two three") |> trace("viwiwd")) == "two three"
  assert driver.text_of(vim_editor("one two three") |> trace("vawawd")) == "three"
  assert driver.text_of(vim_editor("one two three four") |> trace("2wvh2iwd")) == "onehree four"
  assert driver.text_of(vim_editor("one two") |> trace("v9iwd")) == ""
}

pub fn tag_objects_match_nested_elements_and_counts_test() {
  let source = "<p>hello <b>world</b></p>"
  assert driver.text_of(vim_editor(source) |> trace("3ldit")) == "<p></p>"
  assert driver.text_of(vim_editor(source) |> trace("11ldit")) == "<p>hello <b></b></p>"
  assert driver.text_of(vim_editor(source) |> trace("11ld2it")) == "<p></p>"
  assert driver.text_of(vim_editor("<P>one<br/>two</p>") |> trace("3ldit")) == "<P></p>"
  assert driver.text_of(vim_editor("<p></p>") |> trace("cit") |> driver.type_at_selection("X") |> trace("<Esc>")) == "<p>X</p>"
}

pub fn sentence_objects_apply_punctuation_whitespace_and_count_rules_test() {
  assert driver.text_of(vim_editor("One sentence. Two sentence.") |> trace("dis")) == " Two sentence."
  assert driver.text_of(vim_editor("One. Two. Three.") |> trace("d2is")) == "Two. Three."
  assert driver.text_of(vim_editor("One. Two. Three.") |> trace("d2as")) == "Three."
  assert driver.text_of(vim_editor("One!\") Two?") |> trace("dis")) == " Two?"
  assert driver.text_of(vim_editor("One.\n\nTwo.") |> trace("jdis")) == "One.\nTwo."
  assert driver.text_of(vim_editor("  One. Two.") |> trace("dis")) == " Two."
}

pub fn visual_sentence_objects_preserve_anchor_and_expand_backward_test() {
  assert driver.text_of(vim_editor("One. Two. Three.") |> trace("visisd")) == "Two. Three."
  assert driver.text_of(vim_editor("One. Two. Three.") |> trace("vasasd")) == "Three."
  assert driver.text_of(vim_editor("One. Two. Three.") |> trace("10lvh2asd")) == "hree."
}

pub fn visual_tag_objects_expand_through_tags_and_parent_contents_test() {
  let source = "<p>hello <b>world</b></p>"
  assert driver.text_of(vim_editor(source) |> trace("11lvititd")) == "<p>hello </p>"
  assert driver.text_of(vim_editor(source) |> trace("11lvitititd")) == "<p></p>"
  assert driver.text_of(vim_editor(source) |> trace("11lvatatd")) == ""
  assert driver.text_of(vim_editor(source) |> trace("vitd")) == "<p></p>"
}

pub fn mixed_block_register_append_preserves_original_register_kind_test() {
  let block = vim_editor("abcd\nefgh\nijkl") |> trace("<C-v>j\"ayj\"Ayiwgg\"ap")
  assert driver.text_of(block) == "aabcd\neefgh\niefghjkl"
  assert driver.caret(block) == 1
  let character = vim_editor("abcd\nefgh\nijkl") |> trace("\"ayiwj<C-v>j\"Aygg\"ap")
  assert driver.text_of(character) == "aabcde\nibcd\nefgh\nijkl"
  assert driver.caret(character) == 1
}

fn submit_search_prompt(editing: driver.Driver, pattern: String) -> driver.Driver {
  editing |> driver.send(message.PromptChanged(pattern)) |> driver.send(message.PromptSubmitted)
}

pub fn ex_substitution_scopes_and_cursor_match_vim_test() {
  let source = "one one\none one"
  let current = vim_editor(source) |> trace(":") |> submit_search_prompt("s/one/X/g")
  assert driver.text_of(current) == "X X\none one"
  let all = vim_editor(source) |> trace(":") |> submit_search_prompt("%s/one/X/g")
  assert driver.text_of(all) == "X X\nX X"
  assert driver.caret(all) == 4
  assert driver.text_of(trace(all, "u")) == source
}

pub fn ex_ranges_update_registers_and_preserve_yank_cursor_test() {
  let source = "one\ntwo\nthree\nfour"
  let deleted = vim_editor(source) |> trace(":") |> submit_search_prompt("2,3d")
  assert driver.text_of(deleted) == "one\nfour"
  assert driver.text_of(trace(deleted, "\"1p")) == "one\nfour\ntwo\nthree"
  let yanked = vim_editor(source) |> trace(":") |> submit_search_prompt("2,3y")
  assert driver.caret(yanked) == 0
  assert driver.text_of(trace(yanked, "p")) == "one\ntwo\nthree\ntwo\nthree\nfour"
}

pub fn visual_ex_substitution_exits_visual_and_preserves_other_lines_test() {
  let source = "one\none\none"
  let opened = vim_editor(source) |> trace("Vj:")
  let assert option.Some(prompt) = opened.model.prompt
  assert prompt.value == "'<,'>"
  let changed = opened |> submit_search_prompt("'<,'>s/one/X/")
  assert driver.text_of(changed) == "X\nX\none"
  assert driver.text_of(trace(changed, "x")) == "X\n\none"
}

pub fn vim_search_translates_magic_and_preserves_exact_match_positions_test() {
  let boundary = vim_editor("one someone one") |> trace("/") |> submit_search_prompt("\\<one\\>")
  assert driver.caret(boundary) == 12
  assert driver.text_of(trace(boundary, "x")) == "one someone ne"
  assert driver.caret(vim_editor("aaab a+b") |> trace("/") |> submit_search_prompt("a+b")) == 5
  assert driver.caret(vim_editor("a ab aaab") |> trace("/") |> submit_search_prompt("a\\+b")) == 2
  assert driver.caret(vim_editor("one abcd abd") |> trace("/") |> submit_search_prompt("\\v(ab|xy)c?d")) == 4
}

pub fn vim_zero_width_search_respects_normal_visual_and_operator_cursors_test() {
  let source = "abc\ndef\nghi"
  let found = vim_editor(source) |> trace("/") |> submit_search_prompt("$")
  assert driver.caret(found) == 2
  assert driver.caret(trace(found, "n")) == 6
  let deleted = vim_editor(source) |> trace("d/") |> submit_search_prompt("$")
  assert driver.text_of(deleted) == "c\ndef\nghi"
  let visual = vim_editor(source) |> trace("v/") |> submit_search_prompt("$") |> trace("d")
  assert driver.text_of(visual) == "def\nghi"
}

pub fn search_moves_to_match_start_without_selecting_it_test() {
  let found = vim_editor("one two one") |> trace("/") |> submit_search_prompt("two")
  assert driver.caret(found) == 4
  assert driver.anchor(found) == 4
  assert driver.text_of(trace(found, "x")) == "one wo one"
}

pub fn search_repeat_remembers_backward_direction_test() {
  let found = vim_editor("one two one two one") |> trace("$?") |> submit_search_prompt("one") |> trace("n")
  assert driver.caret(found) == 8
  assert driver.caret(trace(found, "Nn")) == 8
}

pub fn visual_search_extends_the_existing_anchor_test() {
  let found = vim_editor("one two one") |> trace("v/") |> submit_search_prompt("two")
  assert driver.anchor(found) == 0
  assert driver.caret(found) == 4
  assert driver.text_of(trace(found, "d")) == "wo one"
}

pub fn operator_search_cancellation_and_change_undo_test() {
  let cancelled = vim_editor("one two one") |> trace("d/") |> driver.send(message.PromptCancelled)
  let found = cancelled |> trace("/") |> submit_search_prompt("two")
  assert driver.text_of(found) == "one two one"
  assert driver.caret(found) == 4
  let changed = vim_editor("one two one") |> trace("c/") |> submit_search_prompt("two") |> driver.type_at_selection("X") |> trace("<Esc>")
  assert driver.text_of(changed) == "Xtwo one"
  assert driver.text_of(trace(changed, "u")) == "one two one"
}
