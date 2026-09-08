import gleam/list
import gleam/option
import glot_frontend/public/editor/code_editor/browser_command
import glot_frontend/public/editor/code_editor/keys
import support/code_editor_driver as driver

pub fn arrow_keys_move_and_shift_extends_test() {
  let editing =
    driver.new("abc\ndef")
    |> driver.press(keys.plain("ArrowRight"))
    |> driver.press(keys.plain("ArrowRight"))

  assert driver.caret(editing) == 2

  let extended = driver.press(editing, keys.shift("ArrowRight"))
  assert driver.selected(extended) == "c"

  let down = driver.press(editing, keys.plain("ArrowDown"))
  assert driver.caret(down) == 6
}

pub fn vertical_movement_keeps_the_goal_column_test() {
  let editing =
    driver.new("longest line\nx\nanother long line")
    |> driver.place_caret(10)
    |> driver.press(keys.plain("ArrowDown"))
    |> driver.press(keys.plain("ArrowDown"))

  // The short middle line clamps the caret, the goal column restores it.
  assert driver.caret(editing) == 25
}

pub fn group_movement_crosses_words_test() {
  let editing =
    driver.new("alpha beta gamma")
    |> driver.press(keys.ctrl("ArrowRight"))

  assert driver.caret(editing) == 5
}

pub fn home_toggles_between_indentation_and_line_start_test() {
  let editing =
    driver.new("    indented")
    |> driver.place_caret(12)
    |> driver.press(keys.plain("Home"))

  assert driver.caret(editing) == 4

  let again = driver.press(editing, keys.plain("Home"))
  assert driver.caret(again) == 0
}

pub fn enter_keeps_the_indentation_and_opens_a_block_test() {
  let editing =
    driver.new("  if (x) {")
    |> driver.place_caret(10)
    |> driver.press(keys.plain("Enter"))

  assert driver.text_of(editing) == "  if (x) {\n    "
}

pub fn tab_indents_and_shift_tab_dedents_test() {
  let indented =
    driver.new("line")
    |> driver.press(keys.plain("Tab"))

  assert driver.text_of(indented) == "  line"

  let dedented = driver.press(indented, keys.shift("Tab"))
  assert driver.text_of(dedented) == "line"
}

pub fn tab_focus_mode_hands_tab_back_to_the_browser_test() {
  let editing =
    driver.new("line")
    |> driver.press(keys.ctrl("m"))

  assert editing.model.tab_focus_mode
  assert editing.model.status == option.Some("Tab moves focus")

  // Tab moves focus from the reducer, so the behaviour cannot depend on when
  // the last render happened.
  let untouched = driver.press(editing, keys.plain("Tab"))
  assert driver.text_of(untouched) == "line"
  assert list.contains(
    untouched.commands,
    browser_command.MoveFocus(forward: True),
  )
}
