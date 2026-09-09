//// Vim sentence text objects, including the whitespace between sentences.

import gleam/int
import gleam/list
import gleam/option.{type Option}
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/movement

type Part {
  Part(from: Int, to: Int, space: Bool)
}

pub fn select(
  doc: Document,
  offset: Int,
  inner: Bool,
  count: Int,
) -> Option(#(Int, Int)) {
  let parts = scan(doc, 0, []) |> list.reverse
  select_parts(parts, index_at(parts, offset, 0), inner, count)
}

pub fn expand(
  doc: Document,
  anchor: Int,
  head: Int,
  inner: Bool,
  count: Int,
) -> Option(#(Int, Int)) {
  let parts = scan(doc, 0, []) |> list.reverse
  let index = index_at(parts, head, 0)
  case part_at(parts, index) {
    option.None -> option.None
    option.Some(part) -> {
      let after_head = movement.next_offset(doc, head)
      let index = case head < anchor, head > anchor {
        True, _ if head <= part.from -> int.max(0, index - 1)
        _, True if after_head >= part.to -> index + 1
        _, _ -> index
      }
      case head < anchor, inner {
        True, True -> {
          let start = int.max(0, index - count + 1)
          select_parts(parts, start, True, index - start + 1)
        }
        True, False -> {
          let start =
            backward_start(
              parts |> list.take(index + 1) |> list.reverse,
              index,
              count,
            )
          let start = case part_at(parts, start - 1) {
            option.Some(part) if part.space -> start - 1
            _ -> start
          }
          select_parts(parts, start, True, index - start + 1)
        }
        False, _ -> select_parts(parts, index, inner, count)
      }
    }
  }
}

fn backward_start(parts: List(Part), index: Int, count: Int) -> Int {
  case parts {
    [] -> 0
    [part, ..rest] ->
      case !part.space && count <= 1 {
        True -> index
        False ->
          backward_start(rest, index - 1, case part.space {
            True -> count
            False -> count - 1
          })
      }
  }
}

fn select_parts(
  parts: List(Part),
  index: Int,
  inner: Bool,
  count: Int,
) -> Option(#(Int, Int)) {
  case part_at(parts, index) {
    option.None -> option.None
    option.Some(first) -> {
      let last_index = case inner {
        True -> int.min(list.length(parts) - 1, index + count - 1)
        False -> sentence_end_index(list.drop(parts, index), index, count)
      }
      case part_at(parts, last_index) {
        option.None -> option.None
        option.Some(last) -> {
          case inner || first.space {
            True -> option.Some(#(first.from, last.to))
            False ->
              case part_at(parts, last_index + 1) {
                option.Some(trailing) if trailing.space ->
                  option.Some(#(first.from, trailing.to))
                _ ->
                  case part_at(parts, index - 1) {
                    option.Some(leading) if leading.space ->
                      option.Some(#(leading.from, last.to))
                    _ -> option.Some(#(first.from, last.to))
                  }
              }
          }
        }
      }
    }
  }
}

fn sentence_end_index(parts: List(Part), index: Int, count: Int) -> Int {
  case parts {
    [] -> int.max(0, index - 1)
    [part, ..rest] ->
      case !part.space && count <= 1 {
        True -> index
        False ->
          sentence_end_index(rest, index + 1, case part.space {
            True -> count
            False -> count - 1
          })
      }
  }
}

fn part_at(parts: List(Part), index: Int) -> Option(Part) {
  case index < 0 {
    True -> option.None
    False -> parts |> list.drop(index) |> list.first |> option.from_result
  }
}

fn index_at(parts: List(Part), offset: Int, index: Int) -> Int {
  case parts {
    [] -> int.max(0, index - 1)
    [part, ..rest] ->
      case offset < part.to {
        True -> index
        False -> index_at(rest, offset, index + 1)
      }
  }
}

fn scan(doc: Document, offset: Int, parts: List(Part)) -> List(Part) {
  case offset >= document.length(doc) {
    True -> parts
    False -> {
      let leading = offset == 0 && space_end(doc, offset) < document.length(doc)
      let space = is_space(movement.grapheme_after(doc, offset)) && !leading
      let end = case space {
        True -> space_end(doc, offset)
        False ->
          content_end(doc, case leading {
            True -> space_end(doc, offset)
            False -> offset
          })
      }
      scan(doc, end, [Part(offset, end, space), ..parts])
    }
  }
}

fn is_space(at: String) -> Bool {
  case at {
    " " | "\t" | "\n" | "\r" -> True
    _ -> False
  }
}

fn space_end(doc: Document, offset: Int) -> Int {
  case
    offset < document.length(doc)
    && is_space(movement.grapheme_after(doc, offset))
  {
    True -> {
      let next = movement.next_offset(doc, offset)
      case
        movement.grapheme_after(doc, offset) == "\n"
        && movement.grapheme_after(doc, next) == "\n"
      {
        True -> next
        False -> space_end(doc, next)
      }
    }
    False -> offset
  }
}

fn content_end(doc: Document, offset: Int) -> Int {
  case offset >= document.length(doc) {
    True -> offset
    False -> {
      let next = movement.next_offset(doc, offset)
      case movement.grapheme_after(doc, offset) {
        "." | "!" | "?" -> {
          let after = closers_end(doc, next)
          case
            after >= document.length(doc)
            || is_space(movement.grapheme_after(doc, after))
          {
            True -> after
            False -> content_end(doc, next)
          }
        }
        " " | "\t" -> {
          let end = horizontal_space_end(doc, offset)
          case end == document.length(doc) {
            True -> offset
            False -> content_end(doc, end)
          }
        }
        "\n" ->
          case movement.grapheme_after(doc, next) == "\n" {
            True -> next
            False -> content_end(doc, next)
          }
        _ -> content_end(doc, next)
      }
    }
  }
}

fn closers_end(doc: Document, offset: Int) -> Int {
  case movement.grapheme_after(doc, offset) {
    ")" | "]" | "\"" | "'" ->
      closers_end(doc, movement.next_offset(doc, offset))
    _ -> offset
  }
}

fn horizontal_space_end(doc: Document, offset: Int) -> Int {
  case movement.grapheme_after(doc, offset) {
    " " | "\t" -> horizontal_space_end(doc, movement.next_offset(doc, offset))
    _ -> offset
  }
}
