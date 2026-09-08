import gleam/option
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/history
import glot_frontend/public/editor/code_editor/selection
import glot_frontend/public/editor/code_editor/state
import glot_frontend/public/editor/code_editor/transaction

pub fn changes_apply_from_the_end_backwards_test() {
  let doc = document.from_string("one two three")
  let changed =
    transaction.apply(doc, [
      transaction.Change(from: 0, to: 3, insert: "1"),
      transaction.Change(from: 8, to: 13, insert: "3"),
    ])

  assert document.to_string(changed) == "1 two 3"
}

pub fn inverted_changes_restore_the_document_test() {
  let doc = document.from_string("alpha\nbeta\ngamma")
  let changes = [
    transaction.Change(from: 0, to: 5, insert: "A"),
    transaction.Change(from: 11, to: 16, insert: ""),
  ]
  let changed = transaction.apply(doc, changes)
  let restored =
    transaction.apply(changed, transaction.invert(doc, changes))

  assert document.to_string(restored) == document.to_string(doc)
}

pub fn offsets_map_through_changes_test() {
  let changes = [transaction.Change(from: 2, to: 4, insert: "xyz")]

  // Before the change: unmoved.
  assert transaction.map_position(changes, 1, False) == 1
  // After the change: shifted by the length difference.
  assert transaction.map_position(changes, 6, False) == 7
  // Inside the change: collapsed to the requested edge.
  assert transaction.map_position(changes, 3, True) == 2
  assert transaction.map_position(changes, 3, False) == 5
}

pub fn an_insertion_at_the_caret_pushes_the_caret_forward_test() {
  let changes = [transaction.Change(from: 4, to: 4, insert: "ab")]
  assert transaction.map_position(changes, 4, False) == 6
}

pub fn applying_a_transaction_records_history_test() {
  let start = state.new("hello")
  let next =
    state.apply(
      start,
      transaction.new(
        [transaction.Change(from: 5, to: 5, insert: "!")],
        transaction.Typing,
      ),
    )

  assert state.text(next) == "hello!"
  assert history.can_undo(next.history)

  let assert option.Some(undone) = state.undo(next)
  assert state.text(undone) == "hello"

  let assert option.Some(redone) = state.redo(undone)
  assert state.text(redone) == "hello!"
}

pub fn history_transactions_do_not_record_themselves_test() {
  let start = state.new("a")
  let typed =
    state.apply(
      start,
      transaction.new(
        [transaction.Change(from: 1, to: 1, insert: "b")],
        transaction.Typing,
      ),
    )
  let replayed =
    state.apply(
      typed,
      transaction.new(
        [transaction.Change(from: 2, to: 2, insert: "c")],
        transaction.History,
      ),
    )

  assert replayed.history == typed.history
}

pub fn replacing_the_document_clears_the_history_test() {
  let start = state.new("a")
  let typed =
    state.apply(
      start,
      transaction.new(
        [transaction.Change(from: 1, to: 1, insert: "b")],
        transaction.Typing,
      ),
    )
  let replaced =
    state.apply(
      typed,
      transaction.new(
        [transaction.Change(from: 0, to: 2, insert: "fresh")],
        transaction.External,
      ),
    )

  assert !history.can_undo(replaced.history)
  assert state.undo(replaced) == option.None
}

pub fn a_selection_only_transaction_leaves_the_document_alone_test() {
  let start = state.new("hello")
  let moved =
    state.apply(start, transaction.selection_only(selection.from(3)))

  assert state.text(moved) == "hello"
  assert selection.head(moved.selection) == 3
}

pub fn selections_are_clamped_into_the_document_test() {
  let start = state.new("abc")
  let moved =
    state.apply(start, transaction.selection_only(selection.from(99)))

  assert selection.head(moved.selection) == 3
}
