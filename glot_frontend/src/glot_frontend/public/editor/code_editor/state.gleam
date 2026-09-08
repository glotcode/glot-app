//// The editing state: a document, a selection, an undo history, and the goal
//// column that vertical movement remembers.
////
//// `apply` is the only way state changes. It records history for ordinary
//// edits, skips recording while replaying history, and starts over when the
//// document is replaced from outside the editor.

import gleam/list
import gleam/option.{type Option}
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/history.{type History}
import glot_frontend/public/editor/code_editor/selection.{type Selection}
import glot_frontend/public/editor/code_editor/transaction.{type Transaction}

pub type State {
  State(
    doc: Document,
    selection: Selection,
    history: History,
    goal_column: Option(Int),
  )
}

pub fn new(source: String) -> State {
  State(
    doc: document.from_string(source),
    selection: selection.from(0),
    history: history.new(),
    goal_column: option.None,
  )
}

pub fn from_document(doc: Document, current: Selection) -> State {
  State(
    doc: doc,
    selection: clamp_selection(doc, current),
    history: history.new(),
    goal_column: option.None,
  )
}

pub fn text(state: State) -> String {
  document.to_string(state.doc)
}

pub fn apply(state: State, tr: Transaction) -> State {
  case tr.changes {
    [] -> apply_selection_only(state, tr)
    changes -> apply_changes(state, tr, changes)
  }
}

fn apply_selection_only(state: State, tr: Transaction) -> State {
  case tr.selection {
    option.None -> state
    option.Some(next) ->
      State(
        ..state,
        selection: clamp_selection(state.doc, next),
        history: history.close_group(state.history),
        goal_column: option.None,
      )
  }
}

fn apply_changes(
  state: State,
  tr: Transaction,
  changes: List(transaction.Change),
) -> State {
  let backward = transaction.invert(state.doc, changes)
  let next_doc = transaction.apply(state.doc, changes)
  let next_selection =
    case tr.selection {
      option.Some(next) -> next
      option.None -> transaction.map_selection(changes, state.selection, False)
    }
    |> clamp_selection(next_doc, _)

  let next_history = case tr.origin {
    transaction.History -> state.history
    transaction.External -> history.new()
    origin ->
      history.record(
        state.history,
        history.Step(forward: changes, backward: backward),
        state.selection,
        next_selection,
        origin,
      )
  }

  State(
    doc: next_doc,
    selection: next_selection,
    history: next_history,
    goal_column: option.None,
  )
}

/// Apply a transaction while keeping the goal column, used by vertical motions.
pub fn apply_keeping_goal(state: State, tr: Transaction) -> State {
  let goal = state.goal_column
  State(..apply(state, tr), goal_column: goal)
}

pub fn set_goal_column(state: State, column: Option(Int)) -> State {
  State(..state, goal_column: column)
}

pub fn undo(state: State) -> Option(State) {
  case history.undo(state.history) {
    option.None -> option.None
    option.Some(#(entry, next_history)) -> {
      let doc =
        list.fold(history.backward_changes(entry), state.doc, transaction.apply)
      option.Some(State(
        doc: doc,
        selection: clamp_selection(doc, entry.selection_before),
        history: next_history,
        goal_column: option.None,
      ))
    }
  }
}

pub fn redo(state: State) -> Option(State) {
  case history.redo(state.history) {
    option.None -> option.None
    option.Some(#(entry, next_history)) -> {
      let doc =
        list.fold(history.forward_changes(entry), state.doc, transaction.apply)
      option.Some(State(
        doc: doc,
        selection: clamp_selection(doc, entry.selection_after),
        history: next_history,
        goal_column: option.None,
      ))
    }
  }
}

pub fn clamp_selection(doc: Document, current: Selection) -> Selection {
  let limit = document.length(doc)
  current
  |> selection.map_offsets(fn(offset) { document.clamp(offset, 0, limit) })
  |> selection.normalize
}
