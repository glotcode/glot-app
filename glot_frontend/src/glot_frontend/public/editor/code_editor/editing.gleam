//// Editing operations, expressed as transactions over a state.
////
//// Every keymap — default, Vim, Emacs — is built from these, so the three
//// binding sets cannot drift apart in what they actually do to the document.

import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/selection.{
  type Range, type Selection,
}
import glot_frontend/public/editor/code_editor/state.{type State}
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/transaction.{
  type Origin, type Transaction,
}

/// Editing settings that come from the surrounding language and viewport.
pub type Context {
  Context(
    indent_unit: String,
    line_comment: Option(String),
    block_comment: Option(#(String, String)),
    page_lines: Int,
  )
}

pub fn default_context() -> Context {
  Context(
    indent_unit: "  ",
    line_comment: option.None,
    block_comment: option.None,
    page_lines: 20,
  )
}

// -- Selection helpers -------------------------------------------------------

fn ranges(state: State) -> List(Range) {
  state.selection.ranges
}

fn collapse(item: Range, offset: Int, extend: Bool) -> Range {
  case extend {
    True -> selection.range(item.anchor, offset)
    False -> selection.cursor(offset)
  }
}

fn selection_of(state: State, updated: List(Range)) -> Selection {
  selection.Selection(
    ranges: updated,
    primary: state.selection.primary,
    rectangular: state.selection.rectangular,
  )
  |> selection.normalize
}

/// Move every range head with `place`.
pub fn move_by(
  state: State,
  extend: Bool,
  place: fn(Document, Int) -> Int,
) -> Transaction {
  ranges(state)
  |> list.map(fn(item) {
    collapse(item, place(state.doc, item.head), extend)
  })
  |> selection_of(state, _)
  |> transaction.selection_only
}

/// Horizontal movement collapses a non-empty selection to the matching edge,
/// which is what every editor here does with a plain arrow key.
pub fn move_horizontally(
  state: State,
  extend: Bool,
  forward: Bool,
  place: fn(Document, Int) -> Int,
) -> Transaction {
  ranges(state)
  |> list.map(fn(item) {
    case extend, selection.is_empty(item) {
      False, False ->
        selection.cursor(case forward {
          True -> selection.end(item)
          False -> selection.start(item)
        })
      _, _ -> collapse(item, place(state.doc, item.head), extend)
    }
  })
  |> selection_of(state, _)
  |> transaction.selection_only
}

/// Vertical movement, returning the goal column to carry forward.
pub fn move_vertically(
  state: State,
  extend: Bool,
  lines: Int,
) -> #(Transaction, Option(Int)) {
  let goal = state.goal_column
  let moved =
    ranges(state)
    |> list.map(fn(item) {
      let #(offset, column) = movement.by_line(state.doc, item.head, lines, goal)
      #(collapse(item, offset, extend), column)
    })

  let next_goal = case moved {
    [#(_, column), ..] -> option.Some(column)
    [] -> goal
  }

  #(
    moved
      |> list.map(fn(pair) { pair.0 })
      |> selection_of(state, _)
      |> transaction.selection_only,
    next_goal,
  )
}

// -- Insertion ---------------------------------------------------------------

/// Replace every selected range with `insert`.
pub fn insert(state: State, insert: String, origin: Origin) -> Transaction {
  let changes =
    ranges(state)
    |> list.map(fn(item) {
      transaction.Change(
        from: selection.start(item),
        to: selection.end(item),
        insert: insert,
      )
    })

  transaction.new(changes, origin)
}

/// Replace one explicit region, used when reconciling a native input event.
pub fn replace_region(
  from: Int,
  to: Int,
  insert: String,
  caret: Int,
  origin: Origin,
) -> Transaction {
  transaction.new([transaction.Change(from: from, to: to, insert: insert)], origin)
  |> transaction.with_selection(selection.from(caret))
}

pub fn insert_newline_and_indent(state: State, context: Context) -> Transaction {
  let changes =
    ranges(state)
    |> list.map(fn(item) {
      let start = selection.start(item)
      let index = document.line_index_at(state.doc, start)
      let content = document.line_text(state.doc, index)
      let indent = text.indentation(content)
      let prefix = text.take(content, start - document.line_start(state.doc, index))
      let extra = case opens_block(string.trim_end(prefix)) {
        True -> context.indent_unit
        False -> ""
      }
      transaction.Change(
        from: start,
        to: selection.end(item),
        insert: "\n" <> indent <> extra,
      )
    })

  transaction.new(changes, transaction.Command)
}

fn opens_block(line: String) -> Bool {
  string.ends_with(line, "{")
  || string.ends_with(line, "[")
  || string.ends_with(line, "(")
}

/// `Ctrl-o` in the default and Emacs keymaps: break the line but stay put.
pub fn split_line(state: State) -> Transaction {
  let changes =
    ranges(state)
    |> list.map(fn(item) {
      transaction.Change(
        from: selection.start(item),
        to: selection.end(item),
        insert: "\n",
      )
    })

  transaction.new(changes, transaction.Command)
  |> transaction.with_selection(
    selection_of(
      state,
      list.map(ranges(state), fn(item) { selection.cursor(selection.start(item)) }),
    ),
  )
}

pub fn insert_blank_line(state: State) -> Transaction {
  let changes =
    ranges(state)
    |> list.map(fn(item) {
      let index = document.line_index_at(state.doc, selection.end(item))
      let end = document.line_end(state.doc, index)
      transaction.Change(from: end, to: end, insert: "\n")
    })

  transaction.new(changes, transaction.Command)
}

// -- Deletion ----------------------------------------------------------------

/// Delete from each range head to `place`, or delete the range when it is not
/// empty.
pub fn delete_by(
  state: State,
  place: fn(Document, Int) -> Int,
  origin: Origin,
) -> Transaction {
  let changes =
    ranges(state)
    |> list.filter_map(fn(item) {
      case selection.is_empty(item) {
        False ->
          Ok(transaction.Change(
            from: selection.start(item),
            to: selection.end(item),
            insert: "",
          ))
        True -> {
          let target = place(state.doc, item.head)
          case target == item.head {
            True -> Error(Nil)
            False ->
              Ok(transaction.Change(
                from: int_min(target, item.head),
                to: int_max(target, item.head),
                insert: "",
              ))
          }
        }
      }
    })

  transaction.new(changes, origin)
}

/// Delete whole lines touched by the selection.
pub fn delete_line(state: State) -> Transaction {
  let changes =
    selected_line_spans(state)
    |> list.map(fn(span) {
      let #(first, last) = span
      let from = document.line_start(state.doc, first)
      let to = case last + 1 < document.line_count(state.doc) {
        True -> document.line_start(state.doc, last + 1)
        False -> document.length(state.doc)
      }
      let from = case
        to == document.length(state.doc) && first > 0
      {
        True -> document.line_end(state.doc, first - 1)
        False -> from
      }
      transaction.Change(from: from, to: to, insert: "")
    })

  transaction.new(changes, transaction.Deleting)
}

// -- Lines -------------------------------------------------------------------

/// The first and last line index touched by each range, merged so overlapping
/// ranges do not edit the same line twice.
pub fn selected_line_spans(state: State) -> List(#(Int, Int)) {
  ranges(state)
  |> list.map(fn(item) {
    #(
      document.line_index_at(state.doc, selection.start(item)),
      line_index_of_end(state.doc, item),
    )
  })
  |> merge_spans([])
}

fn line_index_of_end(doc: Document, item: Range) -> Int {
  let end = selection.end(item)
  let index = document.line_index_at(doc, end)
  case
    !selection.is_empty(item) && end == document.line_start(doc, index) && index > 0
  {
    True -> index - 1
    False -> index
  }
}

fn merge_spans(
  remaining: List(#(Int, Int)),
  collected: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  case remaining, collected {
    [], _ -> list.reverse(collected)
    [current, ..rest], [previous, ..earlier] ->
      case current.0 <= previous.1 + 1 {
        True ->
          merge_spans(rest, [#(previous.0, int_max(previous.1, current.1)), ..earlier])
        False -> merge_spans(rest, [current, ..collected])
      }
    [current, ..rest], [] -> merge_spans(rest, [current])
  }
}

pub fn indent_more(state: State, context: Context) -> Transaction {
  let changes =
    selected_line_spans(state)
    |> list.flat_map(fn(span) {
      line_range(span)
      |> list.map(fn(index) {
        let start = document.line_start(state.doc, index)
        transaction.Change(from: start, to: start, insert: context.indent_unit)
      })
    })

  transaction.new(changes, transaction.Command)
}

pub fn indent_less(state: State, context: Context) -> Transaction {
  let unit_width = text.cluster_count(context.indent_unit)
  let changes =
    selected_line_spans(state)
    |> list.flat_map(fn(span) {
      line_range(span)
      |> list.filter_map(fn(index) {
        let content = document.line_text(state.doc, index)
        let removable = removable_indent(content, unit_width)
        case removable == 0 {
          True -> Error(Nil)
          False -> {
            let start = document.line_start(state.doc, index)
            Ok(transaction.Change(
              from: start,
              to: start + removable,
              insert: "",
            ))
          }
        }
      })
    })

  transaction.new(changes, transaction.Command)
}

fn removable_indent(content: String, unit: Int) -> Int {
  let indent = text.indentation(content)
  case string.starts_with(indent, "\t") {
    True -> 1
    False -> int_min(text.width(indent), unit)
  }
}

/// Re-indent each selected line from the indentation of the previous non-blank
/// line, adding a level after an opening bracket and removing one before a
/// closing bracket. Glot never had a real language indenter, so this stays a
/// predictable structural rule rather than pretending to parse.
pub fn indent_selection(state: State, context: Context) -> Transaction {
  let changes =
    selected_line_spans(state)
    |> list.flat_map(fn(span) { line_range(span) })
    |> list.filter_map(fn(index) {
      let content = document.line_text(state.doc, index)
      let current = text.indentation(content)
      let wanted = wanted_indent(state.doc, index, context)
      case current == wanted {
        True -> Error(Nil)
        False -> {
          let start = document.line_start(state.doc, index)
          Ok(transaction.Change(
            from: start,
            to: start + text.width(current),
            insert: wanted,
          ))
        }
      }
    })

  transaction.new(changes, transaction.Command)
}

fn wanted_indent(doc: Document, index: Int, context: Context) -> String {
  let previous = previous_code_line(doc, index - 1)
  let base = case previous {
    option.Some(line) -> text.indentation(document.line_text(doc, line))
    option.None -> ""
  }
  let opened = case previous {
    option.Some(line) ->
      opens_block(string.trim_end(document.line_text(doc, line)))
    option.None -> False
  }
  let closes = closes_block(string.trim(document.line_text(doc, index)))
  case opened, closes {
    True, True -> base
    True, False -> base <> context.indent_unit
    False, True -> drop_indent_unit(base, context)
    False, False -> base
  }
}

fn closes_block(line: String) -> Bool {
  string.starts_with(line, "}")
  || string.starts_with(line, "]")
  || string.starts_with(line, ")")
}

fn drop_indent_unit(indent: String, context: Context) -> String {
  case string.ends_with(indent, context.indent_unit) {
    True ->
      text.take(indent, text.width(indent) - text.width(context.indent_unit))
    False -> indent
  }
}

fn previous_code_line(doc: Document, index: Int) -> Option(Int) {
  case index < 0 {
    True -> option.None
    False ->
      case string.trim(document.line_text(doc, index)) == "" {
        True -> previous_code_line(doc, index - 1)
        False -> option.Some(index)
      }
  }
}

pub fn move_line_up(state: State) -> Transaction {
  move_lines(state, -1)
}

pub fn move_line_down(state: State) -> Transaction {
  move_lines(state, 1)
}

fn move_lines(state: State, direction: Int) -> Transaction {
  case selected_line_spans(state) {
    [#(first, last)] -> {
      let target = case direction < 0 {
        True -> first - 1
        False -> last + 1
      }
      case target < 0 || target >= document.line_count(state.doc) {
        True -> transaction.new([], transaction.Command)
        False -> {
          let moved = document.line_text(state.doc, target)
          let block =
            line_range(#(first, last))
            |> list.map(fn(index) { document.line_text(state.doc, index) })
          let replacement = case direction < 0 {
            True -> string.join(list.append(block, [moved]), "\n")
            False -> string.join([moved, ..block], "\n")
          }
          let low = int_min(first, target)
          let high = int_max(last, target)
          let from = document.line_start(state.doc, low)
          let to = document.line_end(state.doc, high)
          let shift = shift_for(state.doc, direction, target)
          transaction.new(
            [transaction.Change(from: from, to: to, insert: replacement)],
            transaction.Command,
          )
          |> transaction.with_selection(
            selection.map_offsets(state.selection, fn(offset) { offset + shift }),
          )
        }
      }
    }
    _ -> transaction.new([], transaction.Command)
  }
}

fn shift_for(doc: Document, direction: Int, target: Int) -> Int {
  let distance = text.width(document.line_text(doc, target)) + 1
  case direction < 0 {
    True -> -distance
    False -> distance
  }
}

pub fn copy_line_up(state: State) -> Transaction {
  copy_lines(state, False)
}

pub fn copy_line_down(state: State) -> Transaction {
  copy_lines(state, True)
}

fn copy_lines(state: State, below: Bool) -> Transaction {
  let changes =
    selected_line_spans(state)
    |> list.map(fn(span) {
      let #(first, last) = span
      let block =
        line_range(span)
        |> list.map(fn(index) { document.line_text(state.doc, index) })
        |> string.join("\n")
      case below {
        True -> {
          let end = document.line_end(state.doc, last)
          transaction.Change(from: end, to: end, insert: "\n" <> block)
        }
        False -> {
          let start = document.line_start(state.doc, first)
          transaction.Change(from: start, to: start, insert: block <> "\n")
        }
      }
    })

  transaction.new(changes, transaction.Command)
}

/// Join the selected lines, or the line after the caret, separated by a single
/// space.
pub fn join_lines(state: State, keep_spaces: Bool) -> Transaction {
  let changes =
    selected_line_spans(state)
    |> list.filter_map(fn(span) {
      let #(first, last) = span
      let last = case last == first {
        True -> first + 1
        False -> last
      }
      case last >= document.line_count(state.doc) {
        True -> Error(Nil)
        False -> {
          let from = document.line_end(state.doc, first)
          let to = document.line_start(state.doc, last)
          let tail =
            line_range(#(first + 1, last))
            |> list.map(fn(index) {
              case keep_spaces {
                True -> document.line_text(state.doc, index)
                False -> string.trim_start(document.line_text(state.doc, index))
              }
            })
            |> string.join(case keep_spaces {
              True -> ""
              False -> " "
            })
          let separator = case keep_spaces {
            True -> ""
            False -> " "
          }
          Ok(transaction.Change(
            from: from,
            to: to + text.width(document.line_text(state.doc, last)),
            insert: separator <> tail,
          ))
        }
      }
    })

  transaction.new(changes, transaction.Command)
}

/// Swap the two characters around the caret.
pub fn transpose_chars(state: State) -> Transaction {
  let changes =
    ranges(state)
    |> list.filter_map(fn(item) {
      let offset = item.head
      let before = movement.grapheme_before(state.doc, offset)
      let after = movement.grapheme_after(state.doc, offset)
      case before == "" || after == "" || before == "\n" || after == "\n" {
        True -> Error(Nil)
        False -> {
          let from = movement.prev_offset(state.doc, offset)
          let to = movement.next_offset(state.doc, offset)
          Ok(transaction.Change(from: from, to: to, insert: after <> before))
        }
      }
    })

  transaction.new(changes, transaction.Command)
}

// -- Comments ----------------------------------------------------------------

/// Toggle a line comment across the selected lines, falling back to a block
/// comment for languages that have no line comment syntax.
pub fn toggle_comment(state: State, context: Context) -> Transaction {
  case context.line_comment {
    option.Some(token) -> toggle_line_comment(state, token)
    option.None -> toggle_block_comment(state, context)
  }
}

fn toggle_line_comment(state: State, token: String) -> Transaction {
  let lines =
    selected_line_spans(state)
    |> list.flat_map(fn(span) { line_range(span) })
    |> list.filter(fn(index) {
      string.trim(document.line_text(state.doc, index)) != ""
    })

  let all_commented =
    lines != []
    && list.all(lines, fn(index) {
      string.starts_with(
        string.trim_start(document.line_text(state.doc, index)),
        token,
      )
    })

  let changes = case all_commented {
    True ->
      list.map(lines, fn(index) {
        let content = document.line_text(state.doc, index)
        let indent = text.width(text.indentation(content))
        let start = document.line_start(state.doc, index) + indent
        let rest = text.drop(content, indent)
        let removed = case string.starts_with(rest, token <> " ") {
          True -> text.width(token) + 1
          False -> text.width(token)
        }
        transaction.Change(from: start, to: start + removed, insert: "")
      })
    False -> {
      let column =
        lines
        |> list.map(fn(index) {
          text.width(text.indentation(document.line_text(state.doc, index)))
        })
        |> list.fold(1_000_000, int_min)
      list.map(lines, fn(index) {
        let start = document.line_start(state.doc, index) + column
        transaction.Change(from: start, to: start, insert: token <> " ")
      })
    }
  }

  transaction.new(changes, transaction.Command)
}

pub fn toggle_block_comment(state: State, context: Context) -> Transaction {
  case context.block_comment {
    option.None -> transaction.new([], transaction.Command)
    option.Some(#(open, close)) -> {
      let span = selection.span(state.selection)
      let from = selection.start(span)
      let to = selection.end(span)
      let selected = document.slice(state.doc, from, to)
      case
        string.starts_with(string.trim(selected), open)
        && string.ends_with(string.trim(selected), close)
      {
        True -> {
          let trimmed = string.trim(selected)
          let inner =
            trimmed
            |> string.drop_start(string.length(open))
            |> string.drop_end(string.length(close))
          transaction.new(
            [transaction.Change(from: from, to: to, insert: string.trim(inner))],
            transaction.Command,
          )
        }
        False ->
          transaction.new(
            [
              transaction.Change(
                from: from,
                to: to,
                insert: open <> selected <> close,
              ),
            ],
            transaction.Command,
          )
      }
    }
  }
}

// -- Case --------------------------------------------------------------------

pub fn change_case(state: State, to_upper: Bool) -> Transaction {
  let changes =
    ranges(state)
    |> list.filter_map(fn(item) {
      case selection.is_empty(item) {
        True -> Error(Nil)
        False -> {
          let from = selection.start(item)
          let to = selection.end(item)
          let selected = document.slice(state.doc, from, to)
          Ok(transaction.Change(
            from: from,
            to: to,
            insert: case to_upper {
              True -> string.uppercase(selected)
              False -> string.lowercase(selected)
            },
          ))
        }
      }
    })

  transaction.new(changes, transaction.Command)
}

// -- Selection commands ------------------------------------------------------

pub fn select_all(state: State) -> Transaction {
  transaction.selection_only(
    selection.single(selection.range(0, document.length(state.doc))),
  )
}

pub fn select_line(state: State) -> Transaction {
  selected_line_spans(state)
  |> list.map(fn(span) {
    let #(first, last) = span
    let from = document.line_start(state.doc, first)
    let to = case last + 1 < document.line_count(state.doc) {
      True -> document.line_start(state.doc, last + 1)
      False -> document.length(state.doc)
    }
    selection.range(from, to)
  })
  |> selection_of(state, _)
  |> transaction.selection_only
}

pub fn simplify_selection(state: State) -> Transaction {
  transaction.selection_only(selection.from(selection.head(state.selection)))
}

// -- Small numeric helpers ---------------------------------------------------

fn int_min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

/// Inclusive line range, used by every line-oriented command above.
pub fn line_range(span: #(Int, Int)) -> List(Int) {
  let #(first, last) = span
  case last < first {
    True -> []
    False -> line_range_loop(first, last, [])
  }
}

fn line_range_loop(current: Int, last: Int, collected: List(Int)) -> List(Int) {
  case current > last {
    True -> list.reverse(collected)
    False -> line_range_loop(current + 1, last, [current, ..collected])
  }
}
