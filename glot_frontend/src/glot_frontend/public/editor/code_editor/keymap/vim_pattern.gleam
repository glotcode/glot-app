//// Translate Vim's search syntax without changing the stored search pattern.

import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/search.{type Query}
import glot_frontend/public/editor/code_editor/text

type Magic {
  Magic
  NoMagic
  VeryMagic
  Literal
}

pub fn starts(doc: Document, original: Query) -> List(Int) {
  case original.regexp {
    False -> search.matches(doc, original) |> list.map(fn(span) { span.0 })
    True -> {
      let translated = query(original)
      let captures =
        capture_count(string.to_graphemes(translated.search), False, 0)
      // The final capture marks fallback characters, preserving every skipped
      // codepoint so positions do not depend on searching for matched text again.
      // Captures added after the user pattern preserve its backreference numbers.
      let pattern = "(?:" <> translated.search <> ")|([\\s\\S])"
      case
        regexp.compile(
          pattern,
          regexp.Options(!translated.case_sensitive, False),
        )
      {
        Error(_) -> []
        Ok(compiled) ->
          document.lines_in_range(doc, 0, document.line_count(doc))
          |> list.flat_map(fn(entry) {
            let #(index, line) = entry
            let start = document.line_start(doc, index)
            let widths =
              string.to_utf_codepoints(line.text)
              |> list.map(fn(point) {
                case string.utf_codepoint_to_int(point) > 0xffff {
                  True -> 2
                  False -> 1
                }
              })
            let #(found, _, _) =
              regexp.scan(compiled, line.text)
              |> list.fold(#([], start, widths), fn(acc, match) {
                let #(found, offset, widths) = acc
                // gleam_regexp omits trailing unmatched captures.
                let found = case list.length(match.submatches) <= captures {
                  True -> [offset, ..found]
                  False -> found
                }
                let width = case match.content == "" {
                  True ->
                    case widths {
                      [width, ..] -> width
                      [] -> 0
                    }
                  False -> text.width(match.content)
                }
                #(found, offset + width, consume_width(widths, width))
              })
            list.reverse(found)
          })
      }
    }
  }
}

fn consume_width(widths: List(Int), count: Int) -> List(Int) {
  case widths, count <= 0 {
    _, True -> widths
    [], _ -> []
    [width, ..rest], _ -> consume_width(rest, count - width)
  }
}

fn case_override(tokens: List(String)) -> option.Option(Bool) {
  case tokens {
    [] -> option.None
    ["\\", "c", ..] -> option.Some(False)
    ["\\", "C", ..] -> option.Some(True)
    ["\\", _, ..rest] -> case_override(rest)
    [_, ..rest] -> case_override(rest)
  }
}

fn capture_count(tokens: List(String), collection: Bool, count: Int) -> Int {
  case tokens {
    [] -> count
    ["\\", _, ..rest] -> capture_count(rest, collection, count)
    ["[", ..rest] -> capture_count(rest, True, count)
    ["]", ..rest] -> capture_count(rest, False, count)
    ["(", "?", ..rest] if !collection -> capture_count(rest, collection, count)
    ["(", ..rest] if !collection -> capture_count(rest, collection, count + 1)
    [_, ..rest] -> capture_count(rest, collection, count)
  }
}

pub fn query(query: Query) -> Query {
  case query.regexp {
    False -> query
    True -> {
      let tokens = string.to_graphemes(query.search)
      let sensitive = option.unwrap(case_override(tokens), query.case_sensitive)
      let #(pattern, _) = translate(tokens, Magic, False, sensitive, "")
      search.Query(..query, search: pattern, case_sensitive: sensitive)
    }
  }
}

fn translate(
  tokens: List(String),
  magic: Magic,
  collection: Bool,
  sensitive: Bool,
  out: String,
) -> #(String, Bool) {
  let collection_magic = magic == Magic || magic == VeryMagic
  let escaped_magic = magic == NoMagic || magic == Literal
  case tokens {
    [] -> #(out, sensitive)
    ["\\", code, ..rest] if !collection ->
      case code {
        "m" -> translate(rest, Magic, False, sensitive, out)
        "M" -> translate(rest, NoMagic, False, sensitive, out)
        "v" -> translate(rest, VeryMagic, False, sensitive, out)
        "V" -> translate(rest, Literal, False, sensitive, out)
        "c" -> translate(rest, magic, False, sensitive, out)
        "C" -> translate(rest, magic, False, sensitive, out)
        "<" ->
          translate(
            rest,
            magic,
            False,
            sensitive,
            out <> "(?<![\\p{L}\\p{N}_])(?=[\\p{L}\\p{N}_])",
          )
        ">" ->
          translate(
            rest,
            magic,
            False,
            sensitive,
            out <> "(?<=[\\p{L}\\p{N}_])(?![\\p{L}\\p{N}_])",
          )
        "(" | ")" | "|" | "+" | "?" | "=" if magic != VeryMagic ->
          translate(
            rest,
            magic,
            False,
            sensitive,
            out
              <> case code {
              "=" -> "?"
              _ -> code
            },
          )
        "{" if magic != VeryMagic -> repetition(rest, magic, sensitive, out, "")
        "." | "*" | "[" if escaped_magic ->
          translate(rest, magic, code == "[", sensitive, out <> code)
        "d"
        | "D"
        | "w"
        | "W"
        | "s"
        | "S"
        | "t"
        | "n"
        | "r"
        | "1"
        | "2"
        | "3"
        | "4"
        | "5"
        | "6"
        | "7"
        | "8"
        | "9" -> translate(rest, magic, False, sensitive, out <> "\\" <> code)
        "e" -> translate(rest, magic, False, sensitive, out <> "\\x1b")
        _ -> translate(rest, magic, False, sensitive, out <> escape(code))
      }
    ["\\", code, ..rest] ->
      translate(rest, magic, collection, sensitive, out <> "\\" <> code)
    [first, ..rest] if collection ->
      translate(rest, magic, first != "]", sensitive, out <> first)
    ["[", ..rest] if collection_magic ->
      translate(rest, magic, True, sensitive, out <> "[")
    ["{", ..rest] if magic == VeryMagic ->
      repetition(rest, magic, sensitive, out, "")
    [first, ..rest] -> {
      let special = case magic {
        VeryMagic -> string.contains(".^$*+?()|", first)
        Magic -> string.contains(".^$*", first)
        NoMagic -> first == "^" || first == "$"
        Literal -> False
      }
      translate(
        rest,
        magic,
        False,
        sensitive,
        out
          <> case special {
          True -> first
          False -> escape(first)
        },
      )
    }
  }
}

fn repetition(
  tokens: List(String),
  magic: Magic,
  sensitive: Bool,
  out: String,
  count: String,
) -> #(String, Bool) {
  case tokens {
    [] -> #(out <> "{", sensitive)
    ["}", ..rest] -> {
      let quantifier = case count {
        "-" -> "*?"
        _ -> "{" <> count <> "}"
      }
      translate(rest, magic, False, sensitive, out <> quantifier)
    }
    [first, ..rest] -> repetition(rest, magic, sensitive, out, count <> first)
  }
}

fn escape(character: String) -> String {
  case string.contains("\\.^$*+?()[]{}|", character) {
    True -> "\\" <> character
    False -> character
  }
}
