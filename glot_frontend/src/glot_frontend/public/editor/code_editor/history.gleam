//// Grouped undo and redo.
////
//// An entry is a list of steps; each step keeps both its forward changes and
//// the changes that undo it, so undoing folds the steps backwards and redoing
//// folds them forwards. Grouping appends a step to the newest entry instead of
//// pushing a new one, which is how a run of typed characters, or one completed
//// IME composition, becomes a single undo operation.
////
//// Grouping is decided from the edits themselves — same origin, adjacent
//// offsets — rather than from wall-clock timing, so undo behaviour is
//// reproducible in tests and cannot drift with scheduling.

import gleam/list
import gleam/option.{type Option}
import glot_frontend/public/editor/code_editor/selection.{type Selection}
import glot_frontend/public/editor/code_editor/transaction.{
  type Change, type Origin,
}

/// The largest number of steps that will be folded into one undo entry, so a
/// long typing run cannot grow an entry without bound.
const max_group_steps = 200

/// How many entries are retained.
const max_entries = 300

pub type Step {
  Step(forward: List(Change), backward: List(Change))
}

pub type Entry {
  Entry(
    steps: List(Step),
    selection_before: Selection,
    selection_after: Selection,
    origin: Origin,
  )
}

pub type History {
  History(done: List(Entry), undone: List(Entry))
}

pub fn new() -> History {
  History(done: [], undone: [])
}

pub fn is_empty(history: History) -> Bool {
  history.done == []
}

pub fn can_undo(history: History) -> Bool {
  history.done != []
}

pub fn can_redo(history: History) -> Bool {
  history.undone != []
}

/// Record a step. Recording always discards the redo stack, matching every
/// editor users are likely to come from.
pub fn record(
  history: History,
  step: Step,
  selection_before: Selection,
  selection_after: Selection,
  origin: Origin,
) -> History {
  let done = case history.done {
    [newest, ..rest] ->
      case groups_with(newest, step, origin) {
        True -> [
          Entry(
            ..newest,
            steps: [step, ..newest.steps],
            selection_after: selection_after,
          ),
          ..rest
        ]
        False -> [
          Entry(
            steps: [step],
            selection_before: selection_before,
            selection_after: selection_after,
            origin: origin,
          ),
          newest,
          ..rest
        ]
      }
    [] -> [
      Entry(
        steps: [step],
        selection_before: selection_before,
        selection_after: selection_after,
        origin: origin,
      ),
    ]
  }

  History(done: list.take(done, max_entries), undone: [])
}

/// A boundary forces the next recorded step into a fresh entry. Moving the
/// caret deliberately, switching modes, or running a command all close a group.
pub fn close_group(history: History) -> History {
  case history.done {
    [] -> history
    [newest, ..rest] -> History(..history, done: [close(newest), ..rest])
  }
}

fn close(entry: Entry) -> Entry {
  Entry(..entry, origin: transaction.Command)
}

fn groups_with(entry: Entry, step: Step, origin: Origin) -> Bool {
  case origin == entry.origin, origin {
    False, _ -> False
    True, transaction.Typing -> under_cap(entry) && follows(entry, step)
    True, transaction.Deleting -> under_cap(entry) && precedes(entry, step)
    True, transaction.Composition -> False
    True, _ -> False
  }
}

fn under_cap(entry: Entry) -> Bool {
  list.length(entry.steps) < max_group_steps
}

/// Typing groups while each insertion starts where the previous one ended.
fn follows(entry: Entry, step: Step) -> Bool {
  case newest_change(entry), first_change(step) {
    option.Some(previous), option.Some(next) ->
      next.from
      == previous.from
      + transaction.insert_width(previous.insert)
      || next.from == previous.from
    _, _ -> False
  }
}

/// Backspace groups while each deletion ends where the previous one began.
fn precedes(entry: Entry, step: Step) -> Bool {
  case newest_change(entry), first_change(step) {
    option.Some(previous), option.Some(next) ->
      next.to == previous.from || next.from == previous.from
    _, _ -> False
  }
}

fn newest_change(entry: Entry) -> Option(Change) {
  case entry.steps {
    [newest, ..] -> first_change(newest)
    [] -> option.None
  }
}

fn first_change(step: Step) -> Option(Change) {
  case step.forward {
    [first, ..] -> option.Some(first)
    [] -> option.None
  }
}

pub fn undo(history: History) -> Option(#(Entry, History)) {
  case history.done {
    [] -> option.None
    [newest, ..rest] ->
      option.Some(#(
        newest,
        History(done: rest, undone: [newest, ..history.undone]),
      ))
  }
}

pub fn redo(history: History) -> Option(#(Entry, History)) {
  case history.undone {
    [] -> option.None
    [newest, ..rest] ->
      option.Some(#(newest, History(done: [newest, ..history.done], undone: rest)))
  }
}

/// The changes that undo an entry, already ordered for sequential application.
pub fn backward_changes(entry: Entry) -> List(List(Change)) {
  list.map(entry.steps, fn(step) { step.backward })
}

/// The changes that redo an entry, already ordered for sequential application.
pub fn forward_changes(entry: Entry) -> List(List(Change)) {
  entry.steps
  |> list.reverse
  |> list.map(fn(step) { step.forward })
}
