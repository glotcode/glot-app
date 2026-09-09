//// Screen-column geometry for Vim rectangles. Tabs follow the editor's
//// four-column tab stops. Offsets remain UTF-16 and other cells are graphemes.

import gleam/int
import gleam/option.{type Option}
import gleam/list
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/transaction.{type Change}

pub type Row {
  Row(
    line: Int,
    from: Int,
    to: Int,
    leading: String,
    trailing: String,
    value: String,
    left: Int,
    right: Int,
  )
}

type Cell {
  Cell(value: String, from: Int, to: Int, left: Int, right: Int)
}

fn cells(line: String) -> List(Cell) {
  let #(_, _, result) =
    list.fold(string.to_graphemes(line), #(0, 0, []), fn(acc, value) {
      let #(offset, column, result) = acc
      let next = case value {
        "\t" -> column + 4 - column % 4
        _ -> column + 1
      }
      let end = offset + text.width(value)
      #(end, next, [Cell(value, offset, end, column, next), ..result])
    })
  list.reverse(result)
}

pub fn column(doc: Document, offset: Int) -> Int {
  let line = document.line_index_at(doc, offset)
  let local = offset - document.line_start(doc, line)
  cells(document.line_text(doc, line))
  |> list.fold(0, fn(column, cell) {
    case cell.from < local {
      True -> cell.right
      False -> column
    }
  })
}

fn cell_end(doc: Document, offset: Int) -> Int {
  let at = column(doc, offset)
  let line = document.line_index_at(doc, offset)
  case
    text.grapheme_at(
      document.line_text(doc, line),
      offset - document.line_start(doc, line),
    )
  {
    "\t" -> at + 4 - at % 4
    _ -> at + 1
  }
}

pub fn bounds(doc: Document, anchor: Int, head: Int, goal: Option(Int), to_end: Bool) -> #(Int, Int, Int, Int) {
  let head_column = case goal {
    option.Some(goal) -> case head == document.line_end(doc, document.line_index_at(doc, head)) {
      True -> int.max(column(doc, head), goal)
      False -> column(doc, head)
    }
    _ -> column(doc, head)
  }
  let first = int.min(
      document.line_index_at(doc, anchor),
      document.line_index_at(doc, head),
    )
  let last = int.max(
      document.line_index_at(doc, anchor),
      document.line_index_at(doc, head),
    )
  case to_end {
    True -> #(first, last, column(doc, anchor), longest_end(doc, first, last, column(doc, anchor)))
    False -> #(first, last, int.min(column(doc, anchor), head_column),
      int.max(cell_end(doc, anchor), int.max(cell_end(doc, head), head_column + 1)))
  }
}

fn longest_end(doc: Document, line: Int, last: Int, maximum: Int) -> Int {
  case line > last {
    True -> maximum
    False -> longest_end(doc, line + 1, last, int.max(maximum, column(doc, document.line_end(doc, line))))
  }
}

pub fn rows(doc: Document, anchor: Int, head: Int, goal: Option(Int), to_end: Bool) -> List(Row) {
  let #(first, last, left, right) = bounds(doc, anchor, head, goal, to_end)
  collect_rows(doc, first, last, left, right, [])
}

fn row(doc: Document, line: Int, left: Int, right: Int) -> Row {
  let start = document.line_start(doc, line)
  let content = document.line_text(doc, line)
  let selected =
    cells(content)
    |> list.filter(fn(cell) { cell.left < right && cell.right > left })
  case selected, list.last(selected) {
    [first, ..], Ok(last) -> {
      let value =
        selected
        |> list.map(fn(cell) {
          case cell.left < left || cell.right > right {
            True ->
              string.repeat(
                " ",
                int.min(cell.right, right) - int.max(cell.left, left),
              )
            False -> cell.value
          }
        })
        |> string.concat
      Row(
        line,
        start + first.from,
        start + last.to,
        string.repeat(" ", int.max(0, left - first.left)),
        string.repeat(" ", int.max(0, last.right - right)),
        value,
        left,
        int.min(right, last.right),
      )
    }
    _, _ -> {
      let end = document.line_end(doc, line)
      Row(line, end, end, "", "", "", left, left)
    }
  }
}

pub fn change(row: Row, replacement: String) -> Change {
  transaction.Change(
    row.from,
    row.to,
    row.leading <> replacement <> row.trailing,
  )
}

/// Inserting into a tab splits it; inserting beyond EOL pads the short line.
pub fn insert(doc: Document, line: Int, at: Int, value: String) -> Change {
  let start = document.line_start(doc, line)
  let content = document.line_text(doc, line)
  let found = cells(content) |> list.find(fn(cell) { cell.right > at })
  case found {
    Ok(cell) -> {
      let leading = string.repeat(" ", at - cell.left)
      let trailing = case at == cell.left {
        True -> cell.value
        False -> string.repeat(" ", cell.right - at)
      }
      transaction.Change(
        start + cell.from,
        start + cell.to,
        leading <> value <> trailing,
      )
    }
    Error(_) -> {
      let end = document.line_end(doc, line)
      transaction.Change(
        end,
        end,
        string.repeat(" ", int.max(0, at - column(doc, end))) <> value,
      )
    }
  }
}

fn collect_rows(
  doc: Document,
  line: Int,
  last: Int,
  left: Int,
  right: Int,
  collected: List(Row),
) -> List(Row) {
  case line > last {
    True -> list.reverse(collected)
    False ->
      collect_rows(doc, line + 1, last, left, right, [
        row(doc, line, left, right),
        ..collected
      ])
  }
}

pub fn offset_at_column(doc: Document, line: Int, column: Int) -> Int {
  case
    cells(document.line_text(doc, line))
    |> list.find(fn(cell) { cell.right > column })
  {
    Ok(cell) -> document.line_start(doc, line) + cell.from
    Error(_) -> document.line_end(doc, line)
  }
}

/// Uppercase block delete/change extends each selected row to its own end.
pub fn extend_to_end(doc: Document, selected: Row) -> Row {
  row(doc, selected.line, selected.left,
    int.max(selected.left, column(doc, document.line_end(doc, selected.line))))
}

/// Repeat a register row with its rectangular spacing between copies.
pub fn repeat_value(value: String, width: Int, count: Int, pad_end: Bool) -> String {
  let actual = case list.last(cells(value)) {
    Ok(last) -> last.right
    Error(_) -> 0
  }
  let padded = value <> string.repeat(" ", int.max(0, width - actual))
  string.repeat(padded, count - 1) <> case pad_end {
    True -> padded
    False -> value
  }
}

/// Shift only the suffix beginning at the rectangle's left screen column.
pub fn shift(doc: Document, selected: Row, amount: Int, forward: Bool) -> Option(Change) {
  let end = column(doc, document.line_end(doc, selected.line))
  case selected.left > end {
    True -> option.None
    False -> case forward {
      True -> {
        let whitespace = cells(document.line_text(doc, selected.line))
          |> list.drop_while(fn(cell) { cell.right <= selected.left })
          |> list.take_while(fn(cell) { cell.value == " " || cell.value == "\t" })
        case list.last(whitespace) {
          Error(_) -> option.Some(insert(doc, selected.line, selected.left, string.repeat(" ", amount)))
          Ok(last) -> option.Some(change(
            row(doc, selected.line, selected.left, last.right),
            string.repeat(" ", last.right - selected.left + amount),
          ))
        }
      }
      False -> {
        let whitespace = cells(document.line_text(doc, selected.line))
          |> list.drop_while(fn(cell) { cell.right <= selected.left })
          |> list.take_while(fn(cell) { cell.value == " " || cell.value == "\t" })
        case list.last(whitespace) {
          Error(_) -> option.None
          Ok(last) -> {
            let right = int.min(last.right, selected.left + amount)
            option.Some(change(row(doc, selected.line, selected.left, right), ""))
          }
        }
      }
    }
  }
}
