//// The shared incremental scanner.
////
//// `scan_line` turns one line plus the lexical state it starts in into tokens
//// and the state the next line starts in. Because the state is a small value,
//// the highlighting cache can store it per line, invalidate from the edited
//// line onwards, and stop rescanning as soon as the state converges again.
////
//// Incomplete code is always tokenisable: an unterminated string or comment
//// simply carries its state to the next line, so the document stays editable
//// and predictable while it is being typed.

import glot_frontend/public/editor/code_editor/syntax/cursor.{type Cursor}
import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/syntax/rules.{
  type BlockComment, type Rules, type StringRule,
}
import glot_frontend/public/editor/code_editor/syntax/token.{type Token}
import glot_frontend/public/editor/code_editor/text

/// The lexical state carried between lines.
pub type LexState {
  Normal
  InBlockComment(index: Int, depth: Int)
  InString(index: Int)
  InHeredoc(terminator: String)
}

type Scan {
  Scan(tokens: List(Token), pending_heredoc: Option(String))
}

/// Tokenise one line. The returned tokens are ordered, non-overlapping, and
/// cover the whole line.
pub fn scan_line(
  language_rules: Rules,
  state: LexState,
  line: String,
) -> #(List(Token), LexState) {
  case !language_rules.highlights {
    True -> #([token.Token(kind: token.Plain, start: 0, end: text.width(line))], Normal)
    False -> scan_highlighted(language_rules, state, line)
  }
}

fn scan_highlighted(
  language_rules: Rules,
  state: LexState,
  line: String,
) -> #(List(Token), LexState) {
  case fixed_format_comment(language_rules, line) {
    True -> #(
      [token.Token(kind: token.Comment, start: 0, end: text.width(line))],
      Normal,
    )
    False -> {
      let #(scan, next_state) =
        continue_state(
          language_rules,
          state,
          cursor.new(line),
          0,
          Scan(tokens: [], pending_heredoc: option.None),
        )
      #(merge_plain(list.reverse(scan.tokens), []), resolve(next_state, scan))
    }
  }
}

fn resolve(state: LexState, scan: Scan) -> LexState {
  case state, scan.pending_heredoc {
    Normal, option.Some(terminator) -> InHeredoc(terminator)
    _, _ -> state
  }
}

/// Cobol comments the line when column 7 holds `*` or `/`.
fn fixed_format_comment(language_rules: Rules, line: String) -> Bool {
  case language_rules.fixed_format_comment_column {
    False -> False
    True ->
      case text.grapheme_at(line, 6) {
        "*" | "/" -> True
        _ -> False
      }
  }
}

fn continue_state(
  language_rules: Rules,
  state: LexState,
  rest: Cursor,
  offset: Int,
  scan: Scan,
) -> #(Scan, LexState) {
  case state {
    Normal -> scan_normal(language_rules, rest, offset, scan)

    InBlockComment(index, depth) ->
      case rule_at(language_rules.block_comments, index) {
        option.None -> scan_normal(language_rules, rest, offset, scan)
        option.Some(comment) -> {
          let #(end, remaining, next_depth) =
            consume_block(comment, rest, offset, depth)
          let scan = push(scan, token.Comment, offset, end)
          case next_depth <= 0 {
            True -> scan_normal(language_rules, remaining, end, scan)
            False -> #(scan, InBlockComment(index, next_depth))
          }
        }
      }

    InString(index) ->
      case rule_at(language_rules.strings, index) {
        option.None -> scan_normal(language_rules, rest, offset, scan)
        option.Some(quote) -> {
          let #(end, remaining, closed) = consume_string(quote, rest, offset)
          let scan = push(scan, token.StringLiteral, offset, end)
          case closed {
            True -> scan_normal(language_rules, remaining, end, scan)
            False -> #(scan, InString(index))
          }
        }
      }

    InHeredoc(terminator) ->
      case string.trim(cursor.to_string(rest)) == terminator {
        True -> #(push(scan, token.Meta, offset, offset + cursor.width(rest)), Normal)
        False -> #(
          push(scan, token.StringLiteral, offset, offset + cursor.width(rest)),
          InHeredoc(terminator),
        )
      }
  }
}

fn scan_normal(
  language_rules: Rules,
  rest: Cursor,
  offset: Int,
  scan: Scan,
) -> #(Scan, LexState) {
  case cursor.pop(rest) {
    Error(_) -> #(scan, Normal)
    Ok(#(first, tail)) -> {
      let step = text.width(first)

      case match_line_comment(language_rules, rest) {
        True -> #(
          push(scan, token.Comment, offset, offset + cursor.width(rest)),
          Normal,
        )
        False ->
          case match_block_comment(language_rules, rest) {
            option.Some(#(index, comment)) -> {
              let #(end, remaining, depth) =
                consume_block_open(comment, rest, offset)
              let scan = push(scan, token.Comment, offset, end)
              case depth <= 0 {
                True -> scan_normal(language_rules, remaining, end, scan)
                False -> #(scan, InBlockComment(index, depth))
              }
            }
            option.None ->
              case match_string(language_rules, rest) {
                option.Some(#(index, quote)) -> {
                  let #(end, remaining, closed) =
                    consume_string_open(quote, rest, offset)
                  let scan = push(scan, token.StringLiteral, offset, end)
                  case closed || !quote.multiline {
                    True -> scan_normal(language_rules, remaining, end, scan)
                    False -> #(scan, InString(index))
                  }
                }
                option.None ->
                  case match_meta(language_rules, rest) {
                    option.Some(prefix) -> {
                      let #(end, remaining) =
                        consume_meta(language_rules, prefix, rest, offset)
                      scan_normal(
                        language_rules,
                        remaining,
                        end,
                        push(scan, token.Meta, offset, end),
                      )
                    }
                    option.None ->
                      case is_digit(first) {
                        True -> {
                          let #(end, remaining) = consume_number(rest, offset)
                          scan_normal(
                            language_rules,
                            remaining,
                            end,
                            push(scan, token.NumberLiteral, offset, end),
                          )
                        }
                        False ->
                          case is_identifier_start(language_rules, first) {
                            True -> {
                              let #(end, remaining, word) =
                                consume_identifier(language_rules, rest, offset)
                              let kind =
                                classify_word(language_rules, word, remaining)
                              scan_normal(
                                language_rules,
                                remaining,
                                end,
                                push(scan, kind, offset, end),
                              )
                            }
                            False ->
                              case heredoc_start(language_rules, rest) {
                                option.Some(#(consumed, terminator)) -> {
                                  let end = offset + consumed
                                  let remaining = cursor.drop(rest, consumed)
                                  scan_normal(
                                    language_rules,
                                    remaining,
                                    end,
                                    Scan(
                                      ..push(scan, token.Operator, offset, end),
                                      pending_heredoc: option.Some(terminator),
                                    ),
                                  )
                                }
                                option.None -> {
                                  let kind = case is_space(first) {
                                    True -> token.Plain
                                    False -> operator_kind(first)
                                  }
                                  scan_normal(
                                    language_rules,
                                    tail,
                                    offset + step,
                                    push(scan, kind, offset, offset + step),
                                  )
                                }
                              }
                          }
                      }
                  }
              }
          }
      }
    }
  }
}

// -- Matching ----------------------------------------------------------------

fn match_line_comment(language_rules: Rules, rest: Cursor) -> Bool {
  list.any(language_rules.line_comments, fn(prefix) {
    cursor.starts_with(rest, prefix)
  })
}

fn match_block_comment(
  language_rules: Rules,
  rest: Cursor,
) -> Option(#(Int, BlockComment)) {
  first_match(language_rules.block_comments, 0, fn(comment: BlockComment) {
    cursor.starts_with(rest, comment.open)
  })
}

fn match_string(
  language_rules: Rules,
  rest: Cursor,
) -> Option(#(Int, StringRule)) {
  first_match(language_rules.strings, 0, fn(quote: StringRule) {
    cursor.starts_with(rest, quote.open)
  })
}

fn match_meta(language_rules: Rules, rest: Cursor) -> Option(String) {
  language_rules.meta_prefixes
  |> list.filter(fn(prefix) { cursor.starts_with(rest, prefix) })
  |> list.first
  |> option.from_result
}

fn first_match(
  items: List(a),
  index: Int,
  predicate: fn(a) -> Bool,
) -> Option(#(Int, a)) {
  case items {
    [] -> option.None
    [item, ..rest] ->
      case predicate(item) {
        True -> option.Some(#(index, item))
        False -> first_match(rest, index + 1, predicate)
      }
  }
}

fn rule_at(items: List(a), index: Int) -> Option(a) {
  items
  |> list.drop(index)
  |> list.first
  |> option.from_result
}

// -- Consuming ---------------------------------------------------------------

fn consume_block_open(
  comment: BlockComment,
  rest: Cursor,
  offset: Int,
) -> #(Int, Cursor, Int) {
  let opened = text.width(comment.open)
  consume_block(comment, cursor.drop(rest, opened), offset + opened, 1)
}

fn consume_block(
  comment: BlockComment,
  rest: Cursor,
  offset: Int,
  depth: Int,
) -> #(Int, Cursor, Int) {
  case cursor.pop(rest) {
    Error(_) -> #(offset, cursor.empty(), depth)
    Ok(#(first, tail)) ->
      case cursor.starts_with(rest, comment.close) {
        True -> {
          let width = text.width(comment.close)
          let next = depth - 1
          case next <= 0 {
            True -> #(offset + width, cursor.drop(rest, width), 0)
            False ->
              consume_block(comment, cursor.drop(rest, width), offset + width, next)
          }
        }
        False ->
          case comment.nested && cursor.starts_with(rest, comment.open) {
            True -> {
              let width = text.width(comment.open)
              consume_block(
                comment,
                cursor.drop(rest, width),
                offset + width,
                depth + 1,
              )
            }
            False ->
              consume_block(comment, tail, offset + text.width(first), depth)
          }
      }
  }
}

fn consume_string_open(
  quote: StringRule,
  rest: Cursor,
  offset: Int,
) -> #(Int, Cursor, Bool) {
  let opened = text.width(quote.open)
  consume_string(quote, cursor.drop(rest, opened), offset + opened)
}

fn consume_string(
  quote: StringRule,
  rest: Cursor,
  offset: Int,
) -> #(Int, Cursor, Bool) {
  case cursor.pop(rest) {
    Error(_) -> #(offset, cursor.empty(), False)
    Ok(#(first, tail)) ->
      case quote.escape && first == "\\" {
        True ->
          case cursor.pop(tail) {
            Error(_) -> #(offset + 1, cursor.empty(), False)
            Ok(#(escaped, remaining)) ->
              consume_string(
                quote,
                remaining,
                offset + 1 + text.width(escaped),
              )
          }
        False ->
          case cursor.starts_with(rest, quote.close) {
            True -> {
              let width = text.width(quote.close)
              #(offset + width, cursor.drop(rest, width), True)
            }
            False -> consume_string(quote, tail, offset + text.width(first))
          }
      }
  }
}

fn consume_number(rest: Cursor, offset: Int) -> #(Int, Cursor) {
  consume_while(rest, offset, is_number_char)
}

/// Always consumes at least the first grapheme. A sigil such as Ruby's `@` or
/// Perl's `%` can start an identifier without being allowed inside one, and the
/// scanner must still move forward.
fn consume_identifier(
  language_rules: Rules,
  rest: Cursor,
  offset: Int,
) -> #(Int, Cursor, String) {
  let #(first_width, tail) = case cursor.pop(rest) {
    Ok(#(first, remaining)) -> #(text.width(first), remaining)
    Error(_) -> #(0, cursor.empty())
  }
  let #(end, remaining) =
    consume_while(tail, offset + first_width, fn(grapheme) {
      is_identifier_char(language_rules, grapheme)
    })
  #(end, remaining, cursor.take(rest, end - offset))
}

fn consume_meta(
  language_rules: Rules,
  prefix: String,
  rest: Cursor,
  offset: Int,
) -> #(Int, Cursor) {
  let width = text.width(prefix)
  consume_while(cursor.drop(rest, width), offset + width, fn(grapheme) {
    is_identifier_char(language_rules, grapheme)
  })
}

fn consume_while(
  rest: Cursor,
  offset: Int,
  predicate: fn(String) -> Bool,
) -> #(Int, Cursor) {
  case cursor.pop(rest) {
    Error(_) -> #(offset, cursor.empty())
    Ok(#(first, tail)) ->
      case predicate(first) {
        True -> consume_while(tail, offset + text.width(first), predicate)
        False -> #(offset, rest)
      }
  }
}

/// `<<EOF`, `<<-EOF`, `<<~EOF`, `<<"EOF"` and `<<'EOF'`.
fn heredoc_start(
  language_rules: Rules,
  rest: Cursor,
) -> Option(#(Int, String)) {
  case language_rules.heredocs && cursor.starts_with(rest, "<<") {
    False -> option.None
    True -> {
      let after = cursor.drop(rest, 2)
      let #(indent_width, after) = case cursor.pop(after) {
        Ok(#("-", tail)) -> #(1, tail)
        Ok(#("~", tail)) -> #(1, tail)
        _ -> #(0, after)
      }
      let #(quote_width, body, closing) = case cursor.pop(after) {
        Ok(#("\"", tail)) -> #(1, tail, "\"")
        Ok(#("'", tail)) -> #(1, tail, "'")
        _ -> #(0, after, "")
      }
      let #(end, _) =
        consume_while(body, 0, fn(grapheme) {
          text.classify(grapheme) == text.Word
        })
      case end == 0 {
        True -> option.None
        False ->
          option.Some(#(
            2 + indent_width + quote_width + end + text.width(closing),
            cursor.take(body, end),
          ))
      }
    }
  }
}

// -- Classification ----------------------------------------------------------

fn classify_word(
  language_rules: Rules,
  word: String,
  remaining: Cursor,
) -> token.TokenKind {
  case list.contains(language_rules.keywords, word) {
    True -> token.Keyword
    False ->
      case list.contains(language_rules.types, word) {
        True -> token.TypeName
        False ->
          case list.contains(language_rules.literals, word) {
            True -> token.NumberLiteral
            False ->
              case
                language_rules.call_highlighting
                && cursor.starts_with(cursor.trim_start(remaining), "(")
              {
                True -> token.FunctionName
                False ->
                  case
                    language_rules.capitalized_types && starts_upper_case(word)
                  {
                    True -> token.TypeName
                    False -> token.Plain
                  }
              }
          }
      }
  }
}

fn starts_upper_case(word: String) -> Bool {
  case string.pop_grapheme(word) {
    Ok(#(first, _)) -> first == string.uppercase(first) && first != string.lowercase(first)
    Error(_) -> False
  }
}

fn operator_kind(grapheme: String) -> token.TokenKind {
  case
    list.contains(
      [
        "+", "-", "*", "/", "%", "=", "<", ">", "!", "&", "|", "^", "~", "?",
        ":", ".", ",", ";", "(", ")", "[", "]", "{", "}",
      ],
      grapheme,
    )
  {
    True -> token.Operator
    False -> token.Plain
  }
}

fn is_space(grapheme: String) -> Bool {
  text.classify(grapheme) == text.Whitespace
}

fn is_digit(grapheme: String) -> Bool {
  case grapheme {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn is_number_char(grapheme: String) -> Bool {
  case is_digit(grapheme) {
    True -> True
    False ->
      case string.lowercase(grapheme) {
        "a" | "b" | "c" | "d" | "e" | "f" | "x" | "o" | "u" | "l" | "_" | "." ->
          True
        _ -> False
      }
  }
}

fn is_identifier_start(language_rules: Rules, grapheme: String) -> Bool {
  case text.classify(grapheme) {
    text.Word -> !is_digit(grapheme)
    _ -> list.contains(language_rules.identifier_start_extra, grapheme)
  }
}

fn is_identifier_char(language_rules: Rules, grapheme: String) -> Bool {
  case text.classify(grapheme) {
    text.Word -> True
    _ -> list.contains(language_rules.identifier_extra, grapheme)
  }
}

// -- Token assembly ----------------------------------------------------------

fn push(scan: Scan, kind: token.TokenKind, start: Int, end: Int) -> Scan {
  case end <= start {
    True -> scan
    False ->
      Scan(
        ..scan,
        tokens: [token.Token(kind: kind, start: start, end: end), ..scan.tokens],
      )
  }
}

/// Collapse adjacent tokens of the same kind so the rendered line has as few
/// elements as possible.
fn merge_plain(remaining: List(Token), collected: List(Token)) -> List(Token) {
  case remaining, collected {
    [], _ -> list.reverse(collected)
    [current, ..rest], [previous, ..earlier] ->
      case previous.kind == current.kind && previous.end == current.start {
        True ->
          merge_plain(rest, [
            token.Token(kind: previous.kind, start: previous.start, end: current.end),
            ..earlier
          ])
        False -> merge_plain(rest, [current, ..collected])
      }
    [current, ..rest], [] -> merge_plain(rest, [current])
  }
}
