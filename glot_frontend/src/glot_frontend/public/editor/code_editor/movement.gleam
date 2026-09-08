//// Caret movement over the document.
////
//// All movement is grapheme-aware: single steps land on cluster boundaries and
//// vertical movement remembers a *cluster* column, so moving down through a
//// line of emoji or combining marks never puts the caret inside a character.

import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/text

/// The grapheme starting at `offset`, or `"\n"` at a line break and `""` at the
/// end of the document.
pub fn grapheme_after(doc: Document, offset: Int) -> String {
  let index = document.line_index_at(doc, offset)
  let start = document.line_start(doc, index)
  let content = document.line_text(doc, index)
  case offset - start >= text.width(content) {
    True ->
      case index + 1 < document.line_count(doc) {
        True -> "\n"
        False -> ""
      }
    False -> text.grapheme_at(content, offset - start)
  }
}

/// The grapheme ending at `offset`.
pub fn grapheme_before(doc: Document, offset: Int) -> String {
  case offset <= 0 {
    True -> ""
    False -> grapheme_after(doc, prev_offset(doc, offset))
  }
}

/// The next cluster boundary after `offset`, crossing line breaks.
pub fn next_offset(doc: Document, offset: Int) -> Int {
  let limit = document.length(doc)
  case offset >= limit {
    True -> limit
    False -> {
      let index = document.line_index_at(doc, offset)
      let start = document.line_start(doc, index)
      let content = document.line_text(doc, index)
      case offset - start >= text.width(content) {
        True -> offset + 1
        False -> start + text.next_boundary(content, offset - start)
      }
    }
  }
}

/// The previous cluster boundary before `offset`, crossing line breaks.
pub fn prev_offset(doc: Document, offset: Int) -> Int {
  case offset <= 0 {
    True -> 0
    False -> {
      let index = document.line_index_at(doc, offset)
      let start = document.line_start(doc, index)
      case offset == start {
        True -> offset - 1
        False ->
          start + text.prev_boundary(document.line_text(doc, index), offset - start)
      }
    }
  }
}

pub fn line_start(doc: Document, offset: Int) -> Int {
  document.line_start(doc, document.line_index_at(doc, offset))
}

pub fn line_end(doc: Document, offset: Int) -> Int {
  document.line_end(doc, document.line_index_at(doc, offset))
}

/// The first non-whitespace offset on the line containing `offset`.
pub fn first_non_whitespace(doc: Document, offset: Int) -> Int {
  let index = document.line_index_at(doc, offset)
  let content = document.line_text(doc, index)
  document.line_start(doc, index) + text.width(text.indentation(content))
}

/// `Home` semantics: toggle between the first non-whitespace character and the
/// true start of the line.
pub fn line_boundary_backward(doc: Document, offset: Int) -> Int {
  let indented = first_non_whitespace(doc, offset)
  case offset == indented {
    True -> line_start(doc, offset)
    False -> indented
  }
}

pub fn line_boundary_forward(doc: Document, offset: Int) -> Int {
  line_end(doc, offset)
}

pub fn doc_start(_doc: Document) -> Int {
  0
}

pub fn doc_end(doc: Document) -> Int {
  document.length(doc)
}

/// Column of `offset` measured in grapheme clusters from the start of its line.
pub fn column_at(doc: Document, offset: Int) -> Int {
  let index = document.line_index_at(doc, offset)
  let start = document.line_start(doc, index)
  text.cluster_index(document.line_text(doc, index), offset - start)
}

/// The offset of `column` on `line`, clamped to the end of that line.
pub fn offset_at_column(doc: Document, line: Int, column: Int) -> Int {
  let line = document.clamp(line, 0, document.line_count(doc) - 1)
  let content = document.line_text(doc, line)
  document.line_start(doc, line) + text.offset_of_cluster(content, column)
}

/// Vertical movement. Returns the new offset and the goal column to carry into
/// the next vertical move.
pub fn by_line(
  doc: Document,
  offset: Int,
  lines: Int,
  goal: Option(Int),
) -> #(Int, Int) {
  let index = document.line_index_at(doc, offset)
  let column = case goal {
    option.Some(value) -> value
    option.None -> column_at(doc, offset)
  }
  let target = index + lines
  case target < 0 {
    True -> #(0, column)
    False ->
      case target >= document.line_count(doc) {
        True -> #(document.length(doc), column)
        False -> #(offset_at_column(doc, target, column), column)
      }
  }
}

/// Word-ish movement matching CodeMirror's group motions: skip whitespace, then
/// consume a run of one character class.
pub fn group_right(doc: Document, offset: Int) -> Int {
  let limit = document.length(doc)
  let after_space = skip_forward(doc, offset, limit, text.Whitespace)
  case after_space >= limit {
    True -> limit
    False ->
      consume_forward(
        doc,
        after_space,
        limit,
        text.classify(grapheme_after(doc, after_space)),
      )
  }
}

fn skip_forward(
  doc: Document,
  offset: Int,
  limit: Int,
  class: text.CharClass,
) -> Int {
  case offset >= limit {
    True -> limit
    False ->
      case text.classify(grapheme_after(doc, offset)) == class {
        True -> skip_forward(doc, next_offset(doc, offset), limit, class)
        False -> offset
      }
  }
}

fn consume_forward(
  doc: Document,
  offset: Int,
  limit: Int,
  class: text.CharClass,
) -> Int {
  case offset >= limit {
    True -> limit
    False ->
      case text.classify(grapheme_after(doc, offset)) == class {
        True -> consume_forward(doc, next_offset(doc, offset), limit, class)
        False -> offset
      }
  }
}

pub fn group_left(doc: Document, offset: Int) -> Int {
  let after_space = skip_backward(doc, offset, text.Whitespace)
  case after_space <= 0 {
    True -> 0
    False ->
      consume_backward(
        doc,
        after_space,
        text.classify(grapheme_before(doc, after_space)),
      )
  }
}

fn skip_backward(doc: Document, offset: Int, class: text.CharClass) -> Int {
  case offset <= 0 {
    True -> 0
    False ->
      case text.classify(grapheme_before(doc, offset)) == class {
        True -> skip_backward(doc, prev_offset(doc, offset), class)
        False -> offset
      }
  }
}

fn consume_backward(doc: Document, offset: Int, class: text.CharClass) -> Int {
  case offset <= 0 {
    True -> 0
    False ->
      case text.classify(grapheme_before(doc, offset)) == class {
        True -> consume_backward(doc, prev_offset(doc, offset), class)
        False -> offset
      }
  }
}

/// The word around `offset`, or the empty range at `offset` when it is not in a
/// word.
pub fn word_at(doc: Document, offset: Int) -> #(Int, Int) {
  let start = word_edge_backward(doc, offset)
  let end = word_edge_forward(doc, offset)
  #(start, end)
}

fn word_edge_backward(doc: Document, offset: Int) -> Int {
  case offset <= 0 {
    True -> 0
    False ->
      case text.classify(grapheme_before(doc, offset)) == text.Word {
        True -> word_edge_backward(doc, prev_offset(doc, offset))
        False -> offset
      }
  }
}

fn word_edge_forward(doc: Document, offset: Int) -> Int {
  let limit = document.length(doc)
  case offset >= limit {
    True -> limit
    False ->
      case text.classify(grapheme_after(doc, offset)) == text.Word {
        True -> word_edge_forward(doc, next_offset(doc, offset))
        False -> offset
      }
  }
}

/// The word at the caret, or the next one when the caret sits on whitespace.
/// Emacs' word-case commands walk forwards through the text this way.
pub fn word_after(doc: Document, offset: Int) -> #(Int, Int) {
  let limit = document.length(doc)
  let start = skip_forward(doc, offset, limit, text.Whitespace)
  #(start, word_edge_forward(doc, start))
}

/// Paragraph movement, where a paragraph is a run of non-blank lines.
pub fn paragraph_forward(doc: Document, offset: Int) -> Int {
  let index = document.line_index_at(doc, offset)
  let target = scan_paragraph(doc, index + 1, 1)
  case target >= document.line_count(doc) {
    True -> document.length(doc)
    False -> document.line_start(doc, target)
  }
}

pub fn paragraph_backward(doc: Document, offset: Int) -> Int {
  let index = document.line_index_at(doc, offset)
  let target = scan_paragraph(doc, index - 1, -1)
  case target < 0 {
    True -> 0
    False -> document.line_start(doc, target)
  }
}

fn scan_paragraph(doc: Document, index: Int, step: Int) -> Int {
  case index < 0 || index >= document.line_count(doc) {
    True -> index
    False ->
      case string.trim(document.line_text(doc, index)) == "" {
        True -> index
        False -> scan_paragraph(doc, index + step, step)
      }
  }
}

const opening_brackets = ["(", "[", "{"]

const closing_brackets = [")", "]", "}"]

/// The bracket matching the one next to `offset`, if there is one.
pub fn matching_bracket(doc: Document, offset: Int) -> Option(Int) {
  let after = grapheme_after(doc, offset)
  let before = grapheme_before(doc, offset)
  case list.contains(opening_brackets, after) {
    True -> scan_forward_bracket(doc, next_offset(doc, offset), after, 1)
    False ->
      case list.contains(closing_brackets, before) {
        True ->
          scan_backward_bracket(doc, prev_offset(doc, offset), before, 1)
        False ->
          case list.contains(closing_brackets, after) {
            True -> scan_backward_bracket(doc, offset, after, 1)
            False -> option.None
          }
      }
  }
}

fn partner(bracket: String) -> String {
  case bracket {
    "(" -> ")"
    "[" -> "]"
    "{" -> "}"
    ")" -> "("
    "]" -> "["
    "}" -> "{"
    _ -> ""
  }
}

fn scan_forward_bracket(
  doc: Document,
  offset: Int,
  open: String,
  depth: Int,
) -> Option(Int) {
  let limit = document.length(doc)
  case offset >= limit {
    True -> option.None
    False -> {
      let current = grapheme_after(doc, offset)
      let next_depth = case current == open, current == partner(open) {
        True, _ -> depth + 1
        _, True -> depth - 1
        _, _ -> depth
      }
      case next_depth == 0 {
        True -> option.Some(offset)
        False -> scan_forward_bracket(doc, next_offset(doc, offset), open, next_depth)
      }
    }
  }
}

fn scan_backward_bracket(
  doc: Document,
  offset: Int,
  close: String,
  depth: Int,
) -> Option(Int) {
  case offset <= 0 {
    True -> option.None
    False -> {
      let previous = prev_offset(doc, offset)
      let current = grapheme_after(doc, previous)
      let next_depth = case current == close, current == partner(close) {
        True, _ -> depth + 1
        _, True -> depth - 1
        _, _ -> depth
      }
      case next_depth == 0 {
        True -> option.Some(previous)
        False -> scan_backward_bracket(doc, previous, close, next_depth)
      }
    }
  }
}
