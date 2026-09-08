//// UTF-16 aware text primitives.
////
//// Every offset that crosses the browser boundary — `textarea.selectionStart`,
//// `selectionEnd`, `beforeinput` ranges — is a UTF-16 code unit offset, so the
//// whole editor uses that unit internally and converts here, in one place.
////
//// Movement and deletion, by contrast, must not split a grapheme cluster. The
//// boundary helpers below snap an arbitrary code unit offset onto the nearest
//// cluster edge, so a cursor never lands inside a surrogate pair, a combining
//// sequence, or an emoji ZWJ sequence.

import gleam/list
import gleam/string

/// One grapheme cluster together with the number of UTF-16 code units it
/// occupies.
pub type Cluster {
  Cluster(text: String, width: Int)
}

/// Number of UTF-16 code units in `text`.
pub fn width(text: String) -> Int {
  text
  |> string.to_utf_codepoints
  |> list.fold(0, fn(total, codepoint) {
    total + codepoint_width(string.utf_codepoint_to_int(codepoint))
  })
}

fn codepoint_width(value: Int) -> Int {
  case value >= 0x10000 {
    True -> 2
    False -> 1
  }
}

/// Split `text` into grapheme clusters annotated with their UTF-16 width.
pub fn clusters(text: String) -> List(Cluster) {
  text
  |> string.to_graphemes
  |> list.map(fn(grapheme) { Cluster(text: grapheme, width: width(grapheme)) })
}

/// The substring between two UTF-16 offsets. Offsets outside the string are
/// clamped, and an offset that falls inside a cluster is snapped outward so the
/// result never contains half a character.
pub fn slice(text: String, from: Int, to: Int) -> String {
  let from = int_max(0, from)
  case to <= from {
    True -> ""
    False -> take_slice(clusters(text), 0, from, to, "")
  }
}

fn take_slice(
  remaining: List(Cluster),
  offset: Int,
  from: Int,
  to: Int,
  collected: String,
) -> String {
  case remaining {
    [] -> collected
    [cluster, ..rest] -> {
      let next_offset = offset + cluster.width
      case next_offset <= from {
        True -> take_slice(rest, next_offset, from, to, collected)
        False ->
          case offset >= to {
            True -> collected
            False ->
              take_slice(rest, next_offset, from, to, collected <> cluster.text)
          }
      }
    }
  }
}

/// Everything before `offset`.
pub fn take(text: String, offset: Int) -> String {
  slice(text, 0, offset)
}

/// Everything from `offset` onwards.
pub fn drop(text: String, offset: Int) -> String {
  slice(text, offset, width(text))
}

/// The cluster boundary at or before `offset`.
pub fn cluster_start(text: String, offset: Int) -> Int {
  boundaries(text)
  |> list.filter(fn(boundary) { boundary <= offset })
  |> list.last
  |> unwrap_or(0)
}

/// The cluster boundary at or after `offset`.
pub fn cluster_end(text: String, offset: Int) -> Int {
  boundaries(text)
  |> list.filter(fn(boundary) { boundary >= offset })
  |> list.first
  |> unwrap_or(width(text))
}

/// The previous cluster boundary, strictly before `offset`.
pub fn prev_boundary(text: String, offset: Int) -> Int {
  boundaries(text)
  |> list.filter(fn(boundary) { boundary < offset })
  |> list.last
  |> unwrap_or(0)
}

/// The next cluster boundary, strictly after `offset`.
pub fn next_boundary(text: String, offset: Int) -> Int {
  boundaries(text)
  |> list.filter(fn(boundary) { boundary > offset })
  |> list.first
  |> unwrap_or(width(text))
}

/// Every cluster boundary in `text`, including 0 and the total width.
pub fn boundaries(text: String) -> List(Int) {
  [0, ..boundaries_loop(clusters(text), 0, [])]
}

fn boundaries_loop(
  remaining: List(Cluster),
  offset: Int,
  collected: List(Int),
) -> List(Int) {
  case remaining {
    [] -> list.reverse(collected)
    [cluster, ..rest] -> {
      let next_offset = offset + cluster.width
      boundaries_loop(rest, next_offset, [next_offset, ..collected])
    }
  }
}

fn unwrap_or(result: Result(Int, Nil), fallback: Int) -> Int {
  case result {
    Ok(value) -> value
    Error(_) -> fallback
  }
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

/// Character classes used by word motions, matching CodeMirror's grouping of
/// word characters, whitespace, and everything else.
pub type CharClass {
  Whitespace
  Word
  Symbol
}

pub fn classify(grapheme: String) -> CharClass {
  case grapheme {
    " " | "\t" | "\n" | "\r" | "\u{000B}" | "\u{000C}" | "\u{00A0}" ->
      Whitespace
    "_" -> Word
    _ ->
      case is_alphanumeric(grapheme) {
        True -> Word
        False -> Symbol
      }
  }
}

fn is_alphanumeric(grapheme: String) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [first, ..] -> {
      let value = string.utf_codepoint_to_int(first)
      { value >= 48 && value <= 57 }
      || { value >= 65 && value <= 90 }
      || { value >= 97 && value <= 122 }
      || value > 127
    }
    [] -> False
  }
}

/// The grapheme at `offset`, or `""` at the end of the string.
pub fn grapheme_at(text: String, offset: Int) -> String {
  grapheme_at_loop(clusters(text), 0, offset)
}

fn grapheme_at_loop(
  remaining: List(Cluster),
  position: Int,
  offset: Int,
) -> String {
  case remaining {
    [] -> ""
    [cluster, ..rest] -> {
      let next_position = position + cluster.width
      case offset < next_position {
        True -> cluster.text
        False -> grapheme_at_loop(rest, next_position, offset)
      }
    }
  }
}

/// How many grapheme clusters precede `offset`. Vertical movement uses this as
/// its column, so a caret moving between lines never lands inside a cluster.
pub fn cluster_index(text: String, offset: Int) -> Int {
  cluster_index_loop(clusters(text), 0, 0, offset)
}

fn cluster_index_loop(
  remaining: List(Cluster),
  position: Int,
  index: Int,
  offset: Int,
) -> Int {
  case remaining {
    [] -> index
    [cluster, ..rest] -> {
      let next_position = position + cluster.width
      case offset < next_position {
        True -> index
        False -> cluster_index_loop(rest, next_position, index + 1, offset)
      }
    }
  }
}

/// The UTF-16 offset of the cluster at `index`, clamped to the end of the line.
pub fn offset_of_cluster(text: String, index: Int) -> Int {
  offset_of_cluster_loop(clusters(text), 0, 0, index)
}

fn offset_of_cluster_loop(
  remaining: List(Cluster),
  position: Int,
  current: Int,
  index: Int,
) -> Int {
  case remaining {
    [] -> position
    [cluster, ..rest] ->
      case current >= index {
        True -> position
        False ->
          offset_of_cluster_loop(rest, position + cluster.width, current + 1, index)
      }
  }
}

/// The number of grapheme clusters in `text`.
pub fn cluster_count(text: String) -> Int {
  list.length(clusters(text))
}

/// Leading whitespace of a line, used by indentation-preserving commands.
pub fn indentation(text: String) -> String {
  indentation_loop(string.to_graphemes(text), "")
}

fn indentation_loop(remaining: List(String), collected: String) -> String {
  case remaining {
    [] -> collected
    [grapheme, ..rest] ->
      case grapheme == " " || grapheme == "\t" {
        True -> indentation_loop(rest, collected <> grapheme)
        False -> collected
      }
  }
}
