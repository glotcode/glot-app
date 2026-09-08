//// Document changes and the transactions that carry them.
////
//// Every edit — typed characters, a reconciled native input event, a Vim
//// operator, an undo step — becomes a transaction. Nothing mutates the document
//// outside this module, which is what makes undo grouping, selection mapping,
//// and stale-event rejection provable in tests.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/selection.{type Selection}

pub type Change {
  Change(from: Int, to: Int, insert: String)
}

/// Where a transaction came from. Undo grouping and the stale-callback checks
/// both key off this.
pub type Origin {
  /// Characters typed or reconciled from a native `input` event.
  Typing
  /// One completed IME composition, recorded as a single undo step.
  Composition
  /// Backspace, Delete, and the word/line deletions.
  Deleting
  /// Paste, drop, and other bulk insertions.
  Bulk
  /// An editor command that is not plain typing.
  Command
  /// Applying an undo or redo entry.
  History
  /// Replacing the document from outside the editor.
  External
}

pub type Transaction {
  Transaction(
    changes: List(Change),
    selection: Option(Selection),
    origin: Origin,
    scroll_into_view: Bool,
  )
}

pub fn new(changes: List(Change), origin: Origin) -> Transaction {
  Transaction(
    changes: changes,
    selection: None,
    origin: origin,
    scroll_into_view: True,
  )
}

pub fn with_selection(
  transaction: Transaction,
  next: Selection,
) -> Transaction {
  Transaction(..transaction, selection: Some(next))
}

pub fn selection_only(next: Selection) -> Transaction {
  Transaction(
    changes: [],
    selection: Some(next),
    origin: Command,
    scroll_into_view: True,
  )
}

pub fn without_scroll(transaction: Transaction) -> Transaction {
  Transaction(..transaction, scroll_into_view: False)
}

pub fn is_empty(transaction: Transaction) -> Bool {
  transaction.changes == [] && transaction.selection == None
}

pub fn changes_document(transaction: Transaction) -> Bool {
  transaction.changes != []
}

/// The UTF-16 width of inserted text, counting each line separator as one unit.
pub fn insert_width(insert: String) -> Int {
  document.length(document.from_string(insert))
}

/// Apply changes to a document. Changes are applied from the end backwards so
/// earlier offsets stay valid.
pub fn apply(doc: Document, changes: List(Change)) -> Document {
  changes
  |> sorted
  |> list.reverse
  |> list.fold(doc, fn(current, change) {
    document.replace(current, change.from, change.to, change.insert)
  })
}

/// Changes that restore `doc` after `changes` were applied to it.
pub fn invert(doc: Document, changes: List(Change)) -> List(Change) {
  invert_loop(doc, sorted(changes), 0, [])
}

fn invert_loop(
  doc: Document,
  remaining: List(Change),
  shift: Int,
  collected: List(Change),
) -> List(Change) {
  case remaining {
    [] -> list.reverse(collected)
    [change, ..rest] -> {
      let removed = document.slice(doc, change.from, change.to)
      let inserted = insert_width(change.insert)
      let from = change.from + shift
      let next_shift = shift + inserted - { change.to - change.from }
      invert_loop(doc, rest, next_shift, [
        Change(from: from, to: from + inserted, insert: removed),
        ..collected
      ])
    }
  }
}

/// Map an offset in the pre-change document into the post-change document.
/// `before` decides which edge of a replaced region an offset inside it lands
/// on; an insertion at exactly `offset` always pushes the offset forward, which
/// is what keeps the caret after freshly typed text.
pub fn map_position(changes: List(Change), offset: Int, before: Bool) -> Int {
  map_loop(sorted(changes), offset, before, 0)
}

fn map_loop(
  remaining: List(Change),
  offset: Int,
  before: Bool,
  shift: Int,
) -> Int {
  case remaining {
    [] -> offset + shift
    [change, ..rest] -> {
      let inserted = insert_width(change.insert)
      case offset >= change.to {
        True ->
          map_loop(
            rest,
            offset,
            before,
            shift + inserted - { change.to - change.from },
          )
        False ->
          case offset <= change.from {
            True -> offset + shift
            False ->
              case before {
                True -> change.from + shift
                False -> change.from + shift + inserted
              }
          }
      }
    }
  }
}

pub fn map_selection(
  changes: List(Change),
  current: Selection,
  before: Bool,
) -> Selection {
  current
  |> selection.map_offsets(fn(offset) { map_position(changes, offset, before) })
  |> selection.normalize
}

fn sorted(changes: List(Change)) -> List(Change) {
  list.sort(changes, fn(left, right) {
    case left.from == right.from {
      True -> int.compare(left.to, right.to)
      False -> int.compare(left.from, right.from)
    }
  })
}
