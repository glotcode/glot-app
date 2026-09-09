//// Matching tag objects for Vim. Parsing stays independent of browser DOMs.

import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/text

type Tag {
  Tag(name: String, from: Int, to: Int, closing: Bool)
}

type Pair {
  Pair(open: Tag, close: Tag)
}

pub fn select(
  doc: Document,
  offset: Int,
  inner: Bool,
  count: Int,
) -> Option(#(Int, Int)) {
  let offset = skip_space(doc, offset)
  pairs(doc)
  |> list.filter(fn(pair) { pair.open.from <= offset && offset < pair.close.to })
  |> list.drop(count - 1)
  |> list.first
  |> option.from_result
  |> option.map(fn(pair) { span(pair, inner) })
}

fn skip_space(doc: Document, offset: Int) -> Int {
  case movement.grapheme_after(doc, offset) {
    " " | "\t" -> skip_space(doc, movement.next_offset(doc, offset))
    _ -> offset
  }
}

pub fn expand(
  doc: Document,
  anchor: Int,
  head: Int,
  inner: Bool,
  count: Int,
) -> Option(#(Int, Int)) {
  let from = int.min(anchor, head)
  let to = movement.next_offset(doc, int.max(anchor, head))
  let candidates =
    pairs(doc)
    |> list.filter(fn(pair) { pair.open.from <= from && to <= pair.close.to })
  let spans =
    list.flat_map(candidates, fn(pair) {
      case inner {
        True -> [span(pair, True), span(pair, False)]
        False -> [span(pair, False)]
      }
    })
  spans
  |> list.filter(fn(item) {
    item.0 <= from && to <= item.1 && { item.0 < from || to < item.1 }
  })
  |> list.drop(count - 1)
  |> list.first
  |> option.from_result
}

fn span(pair: Pair, inner: Bool) -> #(Int, Int) {
  case inner {
    True -> #(pair.open.to, pair.close.from)
    False -> #(pair.open.from, pair.close.to)
  }
}

fn pairs(doc: Document) -> List(Pair) {
  scan(doc, 0, [], []) |> list.reverse
}

fn scan(
  doc: Document,
  offset: Int,
  stack: List(Tag),
  found: List(Pair),
) -> List(Pair) {
  case offset >= document.length(doc) {
    True -> found
    False ->
      case movement.grapheme_after(doc, offset) {
        "<" -> {
          let end = tag_end(doc, movement.next_offset(doc, offset), "")
          let body =
            document.slice(doc, offset + 1, int.max(offset + 1, end - 1))
          let closing = string.starts_with(body, "/")
          let content = case closing {
            True -> string.drop_start(body, 1)
            False -> body
          }
          let name = tag_name(content, "") |> string.lowercase
          case name == "", string.ends_with(string.trim(body), "/") {
            True, _ ->
              scan(doc, movement.next_offset(doc, offset), stack, found)
            _, True -> scan(doc, end, stack, found)
            _, _ -> {
              let tag = Tag(name, offset, end, closing)
              case closing {
                False -> scan(doc, end, [tag, ..stack], found)
                True ->
                  case close_tag(stack, name) {
                    option.None -> scan(doc, end, stack, found)
                    option.Some(#(open, rest)) ->
                      scan(doc, end, rest, [Pair(open, tag), ..found])
                  }
              }
            }
          }
        }
        _ -> scan(doc, movement.next_offset(doc, offset), stack, found)
      }
  }
}

fn close_tag(stack: List(Tag), name: String) -> Option(#(Tag, List(Tag))) {
  case stack {
    [] -> option.None
    [tag, ..rest] ->
      case tag.name == name {
        True -> option.Some(#(tag, rest))
        False -> close_tag(rest, name)
      }
  }
}

fn tag_name(content: String, name: String) -> String {
  case string.pop_grapheme(content) {
    Error(_) -> name
    Ok(#(first, rest)) ->
      case text.classify(first) == text.Word || first == ":" || first == "-" {
        True -> tag_name(rest, name <> first)
        False -> name
      }
  }
}

fn tag_end(doc: Document, offset: Int, quote: String) -> Int {
  case offset >= document.length(doc) {
    True -> offset
    False -> {
      let at = movement.grapheme_after(doc, offset)
      let next = movement.next_offset(doc, offset)
      case quote, at {
        "", ">" -> next
        "", "\"" | "", "'" -> tag_end(doc, next, at)
        _, _ if quote == at -> tag_end(doc, next, "")
        _, _ -> tag_end(doc, next, quote)
      }
    }
  }
}
