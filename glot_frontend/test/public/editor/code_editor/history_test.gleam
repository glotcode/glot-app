import gleam/list
import gleam/option
import glot_frontend/public/editor/code_editor/history
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/state.{type State}
import glot_frontend/public/editor/code_editor/transaction

fn type_character(current: State, value: String) -> State {
  let caret = selection.head(current.selection)
  state.apply(
    current,
    transaction.new(
      [transaction.Change(from: caret, to: caret, insert: value)],
      transaction.Typing,
    ),
  )
}

fn backspace(current: State) -> State {
  let caret = selection.head(current.selection)
  state.apply(
    current,
    transaction.new(
      [transaction.Change(from: caret - 1, to: caret, insert: "")],
      transaction.Deleting,
    ),
  )
}

pub fn a_run_of_typing_undoes_as_one_operation_test() {
  let typed =
    list.fold(["h", "e", "l", "l", "o"], state.new(""), type_character)

  assert state.text(typed) == "hello"

  let assert option.Some(undone) = state.undo(typed)
  assert state.text(undone) == ""
}

pub fn a_run_of_deleting_undoes_as_one_operation_test() {
  let typed = list.fold(["a", "b", "c"], state.new(""), type_character)
  let deleted = backspace(backspace(typed))

  assert state.text(deleted) == "a"

  let assert option.Some(undone) = state.undo(deleted)
  assert state.text(undone) == "abc"
}

pub fn moving_the_caret_closes_the_typing_group_test() {
  let typed = list.fold(["a", "b"], state.new(""), type_character)
  let moved = state.apply(typed, transaction.selection_only(selection.from(0)))
  let more = type_character(moved, "z")

  assert state.text(more) == "zab"

  // The characters typed after the deliberate move are their own operation.
  let assert option.Some(undone) = state.undo(more)
  assert state.text(undone) == "ab"
}

pub fn typing_somewhere_else_starts_a_new_group_test() {
  let typed = list.fold(["a", "b", "c"], state.new(""), type_character)
  let elsewhere =
    state.apply(
      typed,
      transaction.new(
        [transaction.Change(from: 0, to: 0, insert: "X")],
        transaction.Typing,
      ),
    )

  let assert option.Some(undone) = state.undo(elsewhere)
  assert state.text(undone) == "abc"
}

pub fn one_composition_is_one_undo_operation_test() {
  let start = state.new("")
  let composed =
    state.apply(
      start,
      transaction.new(
        [transaction.Change(from: 0, to: 0, insert: "\u{3053}\u{3093}")],
        transaction.Composition,
      ),
    )
  let second =
    state.apply(
      composed,
      transaction.new(
        [transaction.Change(from: 2, to: 2, insert: "\u{306B}\u{3061}")],
        transaction.Composition,
      ),
    )

  assert state.text(second) == "\u{3053}\u{3093}\u{306B}\u{3061}"

  // Each completed composition is undone on its own.
  let assert option.Some(undone) = state.undo(second)
  assert state.text(undone) == "\u{3053}\u{3093}"

  let assert option.Some(undone_again) = state.undo(undone)
  assert state.text(undone_again) == ""
}

pub fn undo_restores_the_selection_that_preceded_the_edit_test() {
  let start = state.apply(state.new("abc"), transaction.selection_only(
    selection.single(selection.range(0, 3)),
  ))
  let replaced =
    state.apply(
      start,
      transaction.new(
        [transaction.Change(from: 0, to: 3, insert: "z")],
        transaction.Bulk,
      ),
    )

  let assert option.Some(undone) = state.undo(replaced)
  assert state.text(undone) == "abc"
  assert selection.start(selection.main(undone.selection)) == 0
  assert selection.end(selection.main(undone.selection)) == 3
}

pub fn recording_after_an_undo_drops_the_redo_stack_test() {
  let typed = type_character(state.new(""), "a")
  let assert option.Some(undone) = state.undo(typed)
  let retyped = type_character(undone, "b")

  assert !history.can_redo(retyped.history)
}
