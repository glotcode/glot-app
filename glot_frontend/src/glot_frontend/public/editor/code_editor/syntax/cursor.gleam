//// A line segmented once, shared by every step of the lexer.

import gleam/list
import gleam/string
import glot_frontend/public/editor/code_editor/text

pub type Cursor {
  Cursor(clusters: List(text.Cluster), width: Int)
}

pub fn new(source: String) -> Cursor {
  let clusters = text.clusters(source)
  Cursor(
    clusters,
    list.fold(clusters, 0, fn(total, item) { total + item.width }),
  )
}

pub fn empty() -> Cursor {
  Cursor([], 0)
}

pub fn pop(value: Cursor) -> Result(#(String, Cursor), Nil) {
  case value.clusters {
    [] -> Error(Nil)
    [first, ..rest] ->
      Ok(#(first.text, Cursor(rest, value.width - first.width)))
  }
}

pub fn width(value: Cursor) -> Int {
  value.width
}

pub fn starts_with(value: Cursor, prefix: String) -> Bool {
  case value.clusters {
    [] -> prefix == ""
    [first, ..] ->
      case prefix == first.text || prefix == "" {
        True -> True
        False ->
          case string.starts_with(prefix, first.text) {
            False -> False
            True -> matches_prefix(value.clusters, string.to_graphemes(prefix))
          }
      }
  }
}

fn matches_prefix(clusters: List(text.Cluster), prefix: List(String)) -> Bool {
  case clusters, prefix {
    _, [] -> True
    [first, ..rest], [expected, ..tail] if first.text == expected ->
      matches_prefix(rest, tail)
    _, _ -> False
  }
}

pub fn drop(value: Cursor, count: Int) -> Cursor {
  case value.clusters {
    [first, ..rest] if first.width <= count ->
      drop(Cursor(rest, value.width - first.width), count - first.width)
    _ -> value
  }
}

pub fn take(value: Cursor, count: Int) -> String {
  take_loop(value.clusters, count, [])
}

fn take_loop(
  clusters: List(text.Cluster),
  count: Int,
  pieces: List(String),
) -> String {
  case clusters {
    [first, ..rest] if count > 0 ->
      take_loop(rest, count - first.width, [first.text, ..pieces])
    _ -> pieces |> list.reverse |> string.join("")
  }
}

pub fn to_string(value: Cursor) -> String {
  value.clusters |> list.map(fn(item) { item.text }) |> string.join("")
}

pub fn trim_start(value: Cursor) -> Cursor {
  case pop(value) {
    Ok(#(first, rest)) ->
      case string.trim(first) == "" {
        True -> trim_start(rest)
        False -> value
      }
    Error(_) -> value
  }
}
