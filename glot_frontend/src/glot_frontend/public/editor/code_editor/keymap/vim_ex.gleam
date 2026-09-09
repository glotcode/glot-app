//// Parsing Ex line addresses and preparing atomic substitutions.

import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/string
import glot_frontend/public/editor/code_editor/command.{type EditorCommand}
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/keymap/vim_pattern
import glot_frontend/public/editor/code_editor/movement
import glot_frontend/public/editor/code_editor/search.{type Query}
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/transaction

pub type Addressed {
  Addressed(first: Int, last: Int, body: String, explicit: Bool)
}

pub fn parse(
  input: String,
  current: Int,
  last: Int,
  visual: #(Int, Int),
) -> Option(Addressed) {
  let input = string.trim(input)
  case string.starts_with(input, "%") {
    True ->
      option.Some(Addressed(
        0,
        last,
        string.trim_start(string.drop_start(input, 1)),
        True,
      ))
    False ->
      case address(input, current, last, visual) {
        option.None -> option.Some(Addressed(current, current, input, False))
        option.Some(#(first, rest)) -> {
          let rest = string.trim_start(rest)
          let #(end, body) = case string.pop_grapheme(rest) {
            Ok(#(",", tail)) ->
              option.unwrap(
                address(string.trim_start(tail), current, last, visual),
                #(current, tail),
              )
            Ok(#(";", tail)) ->
              option.unwrap(
                address(string.trim_start(tail), first, last, visual),
                #(first, tail),
              )
            _ -> #(first, rest)
          }
          case first < 0 || end < first || end > last {
            True -> option.None
            False ->
              option.Some(Addressed(first, end, string.trim_start(body), True))
          }
        }
      }
  }
}

fn address(
  input: String,
  current: Int,
  last: Int,
  visual: #(Int, Int),
) -> Option(#(Int, String)) {
  let parsed = case string.pop_grapheme(input) {
    Ok(#(".", rest)) -> option.Some(#(current, rest))
    Ok(#("$", rest)) -> option.Some(#(last, rest))
    Ok(#("+", _)) | Ok(#("-", _)) -> option.Some(#(current, input))
    Ok(#("'", rest)) ->
      case string.pop_grapheme(rest) {
        Ok(#("<", tail)) -> option.Some(#(visual.0, tail))
        Ok(#(">", tail)) -> option.Some(#(visual.1, tail))
        _ -> option.None
      }
    _ -> {
      let #(digits, rest) = number(input, "")
      case int.parse(digits) {
        Ok(value) -> option.Some(#(value - 1, rest))
        Error(_) -> option.None
      }
    }
  }
  option.map(parsed, fn(item) { offsets(item.0, item.1) })
}

fn offsets(value: Int, rest: String) -> #(Int, String) {
  case string.pop_grapheme(rest) {
    Ok(#("+", tail)) -> offset(value, tail, 1)
    Ok(#("-", tail)) -> offset(value, tail, -1)
    _ -> #(value, rest)
  }
}

fn offset(value: Int, tail: String, direction: Int) -> #(Int, String) {
  let #(digits, rest) = number(tail, "")
  let count = case int.parse(digits) {
    Ok(count) -> count
    Error(_) -> 1
  }
  offsets(value + direction * count, rest)
}

fn number(input: String, digits: String) -> #(String, String) {
  case string.pop_grapheme(input) {
    Ok(#(first, rest)) ->
      case string.contains("0123456789", first) {
        True -> number(rest, digits <> first)
        False -> #(digits, input)
      }
    Error(_) -> #(digits, input)
  }
}

pub fn is_substitute(body: String) -> Bool {
  case string.starts_with(body, "substitute") {
    True -> True
    False ->
      case string.to_graphemes(body) {
        ["s", delimiter, ..] -> text.classify(delimiter) == text.Symbol
        _ -> False
      }
  }
}

pub fn substitute(
  doc: Document,
  range: Addressed,
  previous: Query,
) -> Option(#(Query, List(EditorCommand))) {
  let rest = case string.starts_with(range.body, "substitute") {
    True -> string.drop_start(range.body, 10)
    False -> string.drop_start(range.body, 1)
  }
  case string.pop_grapheme(rest) {
    Error(_) -> option.None
    Ok(#(delimiter, rest)) -> {
      let #(pattern, rest) = field(rest, delimiter, "")
      let #(replacement, flags) = field(rest, delimiter, "")
      let pattern = case pattern == "" {
        True -> previous.search
        False -> pattern
      }
      let query =
        search.Query(
          pattern,
          replacement,
          !string.contains(flags, "i"),
          False,
          True,
        )
      let translated = vim_pattern.query(query)
      case
        regexp.compile(
          translated.search,
          regexp.Options(!translated.case_sensitive, False),
        )
      {
        Error(_) -> option.None
        Ok(compiled) -> {
          let all = string.contains(flags, "g")
          let entries =
            document.lines_in_range(doc, range.first, range.last + 1)
          let #(changes, _, caret) =
            list.fold(entries, #([], 0, option.None), fn(acc, entry) {
              let #(changes, delta, _caret) = acc
              let #(index, line) = entry
              let starts =
                vim_pattern.starts(document.from_string(line.text), query)
              let matches = regexp.scan(compiled, line.text)
              let pairs = list.zip(starts, matches)
              let pairs = case all {
                True -> pairs
                False -> list.take(pairs, 1)
              }
              case pairs {
                [] -> acc
                _ -> {
                  let changed =
                    list.fold(list.reverse(pairs), line.text, fn(value, pair) {
                      let #(at, found) = pair
                      text.take(value, at)
                      <> replacement_text(
                        string.to_graphemes(replacement),
                        found,
                        "",
                      )
                      <> text.drop(value, at + text.width(found.content))
                    })
                  let start = document.line_start(doc, index)
                  #(
                    [
                      transaction.Change(
                        start,
                        document.line_end(doc, index),
                        changed,
                      ),
                      ..changes
                    ],
                    delta + text.width(changed) - text.width(line.text),
                    option.Some(start + delta + text.width(changed)),
                  )
                }
              }
            })
          case caret {
            option.None -> option.Some(#(query, []))
            option.Some(caret) -> {
              let changed =
                list.fold(changes, doc, fn(doc, change) {
                  document.replace(doc, change.from, change.to, change.insert)
                })
              option.Some(
                #(query, [
                  command.EditRanges(
                    list.reverse(changes),
                    movement.first_non_whitespace(changed, caret),
                  ),
                ]),
              )
            }
          }
        }
      }
    }
  }
}

fn field(input: String, delimiter: String, out: String) -> #(String, String) {
  case string.pop_grapheme(input) {
    Error(_) -> #(out, "")
    Ok(#(first, rest)) if first == delimiter -> #(out, rest)
    Ok(#("\\", rest)) ->
      case string.pop_grapheme(rest) {
        Ok(#(next, tail)) if next == delimiter ->
          field(tail, delimiter, out <> next)
        Ok(#(next, tail)) -> field(tail, delimiter, out <> "\\" <> next)
        Error(_) -> #(out <> "\\", "")
      }
    Ok(#(first, rest)) -> field(rest, delimiter, out <> first)
  }
}

fn replacement_text(
  tokens: List(String),
  found: regexp.Match,
  out: String,
) -> String {
  case tokens {
    [] -> out
    ["&", ..rest] -> replacement_text(rest, found, out <> found.content)
    ["\\", "r", ..rest] -> replacement_text(rest, found, out <> "\n")
    ["\\", digit, ..rest] -> {
      let value = case int.parse(digit) {
        Ok(0) -> found.content
        Ok(index) ->
          found.submatches
          |> list.drop(index - 1)
          |> list.first
          |> option.from_result
          |> option.flatten
          |> option.unwrap("")
        Error(_) -> digit
      }
      replacement_text(rest, found, out <> value)
    }
    [first, ..rest] -> replacement_text(rest, found, out <> first)
  }
}
