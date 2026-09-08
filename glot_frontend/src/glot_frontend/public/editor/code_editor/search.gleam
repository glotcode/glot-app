//// Search, replace, and selection-match highlighting.
////
//// Matching is line-oriented: a query is located inside each line, which keeps
//// offsets in UTF-16 units without ever materialising the whole document as one
//// grapheme list. Literal search is the default; the panel can opt into regular
//// expressions, case sensitivity, and whole-word matching, exactly as the old
//// search panel did.

import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/text

pub type Query {
  Query(
    search: String,
    replace: String,
    case_sensitive: Bool,
    whole_word: Bool,
    regexp: Bool,
  )
}

pub fn empty_query() -> Query {
  Query(
    search: "",
    replace: "",
    case_sensitive: False,
    whole_word: False,
    regexp: False,
  )
}

pub fn is_usable(query: Query) -> Bool {
  query.search != ""
}

/// Every match in the document, as `#(from, to)` offsets.
pub fn matches(doc: Document, query: Query) -> List(#(Int, Int)) {
  case is_usable(query) {
    False -> []
    True ->
      matches_in_lines(doc, query, 0, document.line_count(doc))
  }
}

/// Matches within `[from, to)` only, used to decorate the rendered viewport.
pub fn matches_in_lines(
  doc: Document,
  query: Query,
  from: Int,
  to: Int,
) -> List(#(Int, Int)) {
  case is_usable(query) {
    False -> []
    True ->
      document.lines_in_range(doc, from, to)
      |> list.flat_map(fn(entry) {
        let #(index, line) = entry
        let start = document.line_start(doc, index)
        line_matches(line.text, query)
        |> list.map(fn(span) { #(start + span.0, start + span.1) })
      })
  }
}

pub fn find_next(
  doc: Document,
  query: Query,
  from: Int,
) -> Option(#(Int, Int)) {
  let all = matches(doc, query)
  case list.filter(all, fn(span) { span.0 >= from }) {
    [first, ..] -> option.Some(first)
    [] ->
      case all {
        [first, ..] -> option.Some(first)
        [] -> option.None
      }
  }
}

pub fn find_previous(
  doc: Document,
  query: Query,
  from: Int,
) -> Option(#(Int, Int)) {
  let all = matches(doc, query)
  case list.filter(all, fn(span) { span.1 <= from }) |> list.last {
    Ok(found) -> option.Some(found)
    Error(_) ->
      case list.last(all) {
        Ok(found) -> option.Some(found)
        Error(_) -> option.None
      }
  }
}

pub fn count(doc: Document, query: Query) -> Int {
  list.length(matches(doc, query))
}

// -- Line level --------------------------------------------------------------

fn line_matches(line: String, query: Query) -> List(#(Int, Int)) {
  case query.regexp {
    True -> regexp_matches(line, query)
    False -> literal_matches(line, query)
  }
  |> list.filter(fn(span) { whole_word_ok(line, query, span) })
}

fn literal_matches(line: String, query: Query) -> List(#(Int, Int)) {
  let haystack = case query.case_sensitive {
    True -> line
    False -> string.lowercase(line)
  }
  let needle = case query.case_sensitive {
    True -> query.search
    False -> string.lowercase(query.search)
  }
  literal_loop(haystack, needle, 0, [])
}

fn literal_loop(
  rest: String,
  needle: String,
  offset: Int,
  collected: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  case string.pop_grapheme(rest) {
    Error(_) -> list.reverse(collected)
    Ok(#(first, tail)) ->
      case string.starts_with(rest, needle) {
        True -> {
          let width = text.width(needle)
          literal_loop(text.drop(rest, width), needle, offset + width, [
            #(offset, offset + width),
            ..collected
          ])
        }
        False ->
          literal_loop(tail, needle, offset + text.width(first), collected)
      }
  }
}

fn regexp_matches(line: String, query: Query) -> List(#(Int, Int)) {
  let options =
    regexp.Options(case_insensitive: !query.case_sensitive, multi_line: False)
  case regexp.compile(query.search, options) {
    Error(_) -> []
    Ok(compiled) ->
      regexp.scan(compiled, line)
      |> list.fold(#([], 0), fn(accumulator, found) {
        let #(collected, cursor) = accumulator
        case found.content == "" {
          True -> #(collected, cursor)
          False -> {
            let remaining = text.drop(line, cursor)
            case index_of(remaining, found.content) {
              option.None -> #(collected, cursor)
              option.Some(relative) -> {
                let start = cursor + relative
                let end = start + text.width(found.content)
                #([#(start, end), ..collected], end)
              }
            }
          }
        }
      })
      |> fn(accumulator) { list.reverse(accumulator.0) }
  }
}

fn index_of(haystack: String, needle: String) -> Option(Int) {
  index_loop(haystack, needle, 0)
}

fn index_loop(rest: String, needle: String, offset: Int) -> Option(Int) {
  case string.pop_grapheme(rest) {
    Error(_) -> option.None
    Ok(#(first, tail)) ->
      case string.starts_with(rest, needle) {
        True -> option.Some(offset)
        False -> index_loop(tail, needle, offset + text.width(first))
      }
  }
}

fn whole_word_ok(line: String, query: Query, span: #(Int, Int)) -> Bool {
  case query.whole_word {
    False -> True
    True -> {
      let before = case span.0 <= 0 {
        True -> ""
        False -> text.grapheme_at(line, text.prev_boundary(line, span.0))
      }
      let after = text.grapheme_at(line, span.1)
      text.classify(before) != text.Word && text.classify(after) != text.Word
    }
  }
}
