//// The indexed line document.
////
//// A document is the list of its lines plus the cached UTF-16 width of each
//// line. Offsets are document-wide UTF-16 code unit offsets in which each line
//// separator counts as exactly one unit, which is what a `textarea` reports and
//// what `beforeinput` ranges use.
////
//// Glot already caps a file at 100,000 characters, so line lists stay in the
//// low thousands and a whole-document rebuild on edit is cheap. The editor
//// therefore keeps the representation simple and spends its incrementality
//// budget on lexing instead.

import gleam/list
import gleam/string
import glot_frontend/public/editor/code_editor/text

pub type Line {
  Line(text: String, width: Int)
}

pub type Document {
  Document(lines: List(Line), line_count: Int, length: Int)
}

/// A line/column pair. `column` is a UTF-16 offset inside the line.
pub type Position {
  Position(line: Int, column: Int)
}

pub fn from_string(source: String) -> Document {
  let lines =
    source
    |> normalize_newlines
    |> string.split("\n")
    |> list.map(make_line)

  build(lines)
}

fn normalize_newlines(source: String) -> String {
  source
  |> string.replace("\r\n", "\n")
  |> string.replace("\r", "\n")
}

fn make_line(content: String) -> Line {
  Line(text: content, width: text.width(content))
}

fn build(lines: List(Line)) -> Document {
  let line_count = list.length(lines)
  let content_width =
    list.fold(lines, 0, fn(total, item) { total + item.width })
  Document(
    lines: lines,
    line_count: line_count,
    length: content_width + line_count - 1,
  )
}

pub fn empty() -> Document {
  from_string("")
}

pub fn to_string(document: Document) -> String {
  document.lines
  |> list.map(fn(item) { item.text })
  |> string.join("\n")
}

pub fn length(document: Document) -> Int {
  document.length
}

pub fn line_count(document: Document) -> Int {
  document.line_count
}

/// The line at `index`, clamped into the document.
pub fn line(document: Document, index: Int) -> Line {
  let index = clamp(index, 0, document.line_count - 1)
  case list.drop(document.lines, index) {
    [found, ..] -> found
    [] -> Line(text: "", width: 0)
  }
}

pub fn line_text(document: Document, index: Int) -> String {
  line(document, index).text
}

/// The document offset where line `index` starts.
pub fn line_start(document: Document, index: Int) -> Int {
  let index = clamp(index, 0, document.line_count - 1)
  document.lines
  |> list.take(index)
  |> list.fold(0, fn(total, item) { total + item.width + 1 })
}

/// The document offset where line `index` ends, before its separator.
pub fn line_end(document: Document, index: Int) -> Int {
  line_start(document, index) + line(document, index).width
}

/// The index of the line containing `offset`.
pub fn line_index_at(document: Document, offset: Int) -> Int {
  let offset = clamp(offset, 0, document.length)
  line_index_loop(document.lines, offset, 0, 0)
}

fn line_index_loop(
  remaining: List(Line),
  offset: Int,
  start: Int,
  index: Int,
) -> Int {
  case remaining {
    [] -> index
    [_] -> index
    [current, ..rest] -> {
      let next_start = start + current.width + 1
      case offset < next_start {
        True -> index
        False -> line_index_loop(rest, offset, next_start, index + 1)
      }
    }
  }
}

pub fn position_at(document: Document, offset: Int) -> Position {
  let offset = clamp(offset, 0, document.length)
  let index = line_index_at(document, offset)
  Position(line: index, column: offset - line_start(document, index))
}

pub fn offset_at(document: Document, position: Position) -> Int {
  let index = clamp(position.line, 0, document.line_count - 1)
  let target = line(document, index)
  line_start(document, index) + clamp(position.column, 0, target.width)
}

pub fn slice(document: Document, from: Int, to: Int) -> String {
  let from = clamp(from, 0, document.length)
  let to = clamp(to, from, document.length)
  case from == to {
    True -> ""
    False -> {
      let first = line_index_at(document, from)
      let last = line_index_at(document, to)
      case first == last {
        True -> {
          let start = line_start(document, first)
          let item = line(document, first)
          case from == start && to == start + item.width {
            True -> item.text
            False -> text.slice(item.text, from - start, to - start)
          }
        }
        False -> {
          let first_start = line_start(document, first)
          let head =
            text.drop(line_text(document, first), from - first_start)
          let middle =
            document.lines
            |> list.drop(first + 1)
            |> list.take(last - first - 1)
            |> list.map(fn(item) { item.text })
          let last_start = line_start(document, last)
          let tail = text.take(line_text(document, last), to - last_start)
          string.join(list.flatten([[head], middle, [tail]]), "\n")
        }
      }
    }
  }
}

/// Replace the text between `from` and `to` with `insert`.
pub fn replace(
  document: Document,
  from: Int,
  to: Int,
  insert: String,
) -> Document {
  let from = clamp(from, 0, document.length)
  let to = clamp(to, from, document.length)
  let first = line_index_at(document, from)
  let last = line_index_at(document, to)
  let first_start = line_start(document, first)
  let last_start = line_start(document, last)
  let #(prefix, suffix) = case first == last {
    True -> retained_parts(line(document, first), from - first_start, to - first_start)
    False -> #(
      text.take(line_text(document, first), from - first_start),
      text.drop(line_text(document, last), to - last_start),
    )
  }
  let replacement =
    { prefix <> normalize_newlines(insert) <> suffix }
    |> string.split("\n")
    |> list.map(make_line)

  build(
    list.flatten([
      list.take(document.lines, first),
      replacement,
      list.drop(document.lines, last + 1),
    ]),
  )
}

// A typical edit needs both ends of the same line. Share its segmentation,
// and reuse the source directly when inserting at either edge.
fn retained_parts(line: Line, from: Int, to: Int) -> #(String, String) {
  case from, to {
    0, 0 -> #("", line.text)
    _, _ if from == line.width -> #(line.text, "")
    0, _ if to == line.width -> #("", "")
    _, _ -> {
      let clusters = text.clusters(line.text)
      #(
        text.slice_clusters(clusters, 0, from),
        text.slice_clusters(clusters, to, line.width),
      )
    }
  }
}

/// Lines `from` (inclusive) through `to` (exclusive), used by viewport
/// rendering.
pub fn lines_in_range(
  document: Document,
  from: Int,
  to: Int,
) -> List(#(Int, Line)) {
  let from = clamp(from, 0, document.line_count)
  let to = clamp(to, from, document.line_count)
  document.lines
  |> list.drop(from)
  |> list.take(to - from)
  |> list.index_map(fn(item, offset) { #(from + offset, item) })
}

pub fn clamp(value: Int, low: Int, high: Int) -> Int {
  case value < low {
    True -> low
    False ->
      case value > high {
        True -> high
        False -> value
      }
  }
}
