//// Vim text objects.
////
//// Each function answers the `#(from, to)` span an `i`/`a` object selects
//// around an offset, or `None` when the object is not present there.

import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/text

pub type Span =
  #(Int, Int)

/// `iw` / `aw`, and the `W` variants that treat any non-space run as a word.
pub fn word(
  doc: Document,
  offset: Int,
  inner: Bool,
  big: Bool,
) -> Option(Span) {
  let limit = document.length(doc)
  case limit == 0 {
    True -> option.None
    False -> {
      let at = movement.grapheme_after(doc, offset)
      let class = class_of(at, big)
      let start = scan_back(doc, offset, class, big)
      let end = scan_forward(doc, offset, limit, class, big)
      case inner {
        True -> option.Some(#(start, end))
        False -> {
          let trailing = scan_forward(doc, end, limit, Space, big)
          case trailing > end {
            True -> option.Some(#(start, trailing))
            False -> option.Some(#(scan_back(doc, start, Space, big), end))
          }
        }
      }
    }
  }
}

type Class {
  Space
  WordChar
  SymbolChar
}

fn class_of(grapheme: String, big: Bool) -> Class {
  case text.classify(grapheme) {
    text.Whitespace -> Space
    text.Word ->
      case big {
        True -> WordChar
        False -> WordChar
      }
    text.Symbol ->
      case big {
        True -> WordChar
        False -> SymbolChar
      }
  }
}

fn scan_back(doc: Document, offset: Int, class: Class, big: Bool) -> Int {
  case offset <= 0 {
    True -> 0
    False -> {
      let previous = movement.prev_offset(doc, offset)
      case
        movement.grapheme_after(doc, previous) != "\n"
        && class_of(movement.grapheme_after(doc, previous), big) == class
      {
        True -> scan_back(doc, previous, class, big)
        False -> offset
      }
    }
  }
}

fn scan_forward(
  doc: Document,
  offset: Int,
  limit: Int,
  class: Class,
  big: Bool,
) -> Int {
  case offset >= limit {
    True -> limit
    False -> {
      let at = movement.grapheme_after(doc, offset)
      case at != "\n" && class_of(at, big) == class {
        True -> scan_forward(doc, movement.next_offset(doc, offset), limit, class, big)
        False -> offset
      }
    }
  }
}

/// `ip` / `ap`: a run of non-blank lines, optionally with the blank lines after
/// it.
pub fn paragraph(doc: Document, offset: Int, inner: Bool) -> Option(Span) {
  let index = document.line_index_at(doc, offset)
  let blank = is_blank(doc, index)
  let first = paragraph_edge(doc, index, -1, blank)
  let last = paragraph_edge(doc, index, 1, blank)
  let end = case inner {
    True -> document.line_end(doc, last)
    False -> document.line_end(doc, paragraph_edge(doc, last + 1, 1, !blank))
  }
  option.Some(#(document.line_start(doc, first), end))
}

fn paragraph_edge(doc: Document, index: Int, step: Int, blank: Bool) -> Int {
  let next = index + step
  case next < 0 || next >= document.line_count(doc) {
    True -> document.clamp(index, 0, document.line_count(doc) - 1)
    False ->
      case is_blank(doc, next) == blank {
        True -> paragraph_edge(doc, next, step, blank)
        False -> document.clamp(index, 0, document.line_count(doc) - 1)
      }
  }
}

fn is_blank(doc: Document, index: Int) -> Bool {
  string.trim(document.line_text(doc, index)) == ""
}

/// `i(` / `a(` and friends, including the `b` and `B` aliases.
pub fn brackets(
  doc: Document,
  offset: Int,
  open: String,
  close: String,
  inner: Bool,
) -> Option(Span) {
  case find_open(doc, offset, open, close, 0) {
    option.None -> option.None
    option.Some(start) ->
      case find_close(doc, movement.next_offset(doc, start), open, close, 1) {
        option.None -> option.None
        option.Some(end) ->
          case inner {
            True -> option.Some(#(movement.next_offset(doc, start), end))
            False -> option.Some(#(start, movement.next_offset(doc, end)))
          }
      }
  }
}

fn find_open(
  doc: Document,
  offset: Int,
  open: String,
  close: String,
  depth: Int,
) -> Option(Int) {
  case movement.grapheme_after(doc, offset) == open && depth == 0 {
    True -> option.Some(offset)
    False ->
      case offset <= 0 {
        True -> option.None
        False -> {
          let previous = movement.prev_offset(doc, offset)
          let at = movement.grapheme_after(doc, previous)
          let next_depth = case at == close, at == open {
            True, _ -> depth + 1
            _, True -> depth - 1
            _, _ -> depth
          }
          case at == open && next_depth < 0 {
            True -> option.Some(previous)
            False -> find_open(doc, previous, open, close, int_max(next_depth, 0))
          }
        }
      }
  }
}

fn find_close(
  doc: Document,
  offset: Int,
  open: String,
  close: String,
  depth: Int,
) -> Option(Int) {
  case offset >= document.length(doc) {
    True -> option.None
    False -> {
      let at = movement.grapheme_after(doc, offset)
      let next_depth = case at == open, at == close {
        True, _ -> depth + 1
        _, True -> depth - 1
        _, _ -> depth
      }
      case next_depth == 0 {
        True -> option.Some(offset)
        False ->
          find_close(doc, movement.next_offset(doc, offset), open, close, next_depth)
      }
    }
  }
}

/// `i"` / `a"` and the other quote objects, resolved inside the current line.
pub fn quotes(
  doc: Document,
  offset: Int,
  quote: String,
  inner: Bool,
) -> Option(Span) {
  let index = document.line_index_at(doc, offset)
  let start = document.line_start(doc, index)
  let line = document.line_text(doc, index)
  case quote_positions(line, quote, 0, []) {
    [] -> option.None
    positions ->
      case surrounding_pair(positions, offset - start) {
        option.None -> option.None
        option.Some(#(open, close)) ->
          case inner {
            True ->
              option.Some(#(
                start + open + text.width(quote),
                start + close,
              ))
            False ->
              option.Some(#(start + open, start + close + text.width(quote)))
          }
      }
  }
}

fn quote_positions(
  line: String,
  quote: String,
  offset: Int,
  collected: List(Int),
) -> List(Int) {
  case string.pop_grapheme(line) {
    Error(_) -> reverse(collected)
    Ok(#(first, tail)) ->
      case first == "\\" {
        True ->
          case string.pop_grapheme(tail) {
            Ok(#(escaped, rest)) ->
              quote_positions(
                rest,
                quote,
                offset + 1 + text.width(escaped),
                collected,
              )
            Error(_) -> reverse(collected)
          }
        False ->
          case first == quote {
            True ->
              quote_positions(tail, quote, offset + text.width(first), [
                offset,
                ..collected
              ])
            False ->
              quote_positions(tail, quote, offset + text.width(first), collected)
          }
      }
  }
}

fn surrounding_pair(positions: List(Int), offset: Int) -> Option(#(Int, Int)) {
  case positions {
    [open, close, ..rest] ->
      case offset >= open && offset <= close {
        True -> option.Some(#(open, close))
        False -> surrounding_pair(rest, offset)
      }
    _ -> option.None
  }
}

fn reverse(items: List(Int)) -> List(Int) {
  reverse_loop(items, [])
}

fn reverse_loop(items: List(Int), collected: List(Int)) -> List(Int) {
  case items {
    [] -> collected
    [first, ..rest] -> reverse_loop(rest, [first, ..collected])
  }
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}
