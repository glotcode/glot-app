//// The incremental highlighting cache.
////
//// Lexical state is cached per line. An edit drops the cached states from the
//// edited line onwards; the next render re-scans forward from the newest
//// surviving state, and stops as soon as the recomputed state matches the one
//// already cached — the point at which the rest of the document is provably
//// unchanged.
////
//// Only viewport lines, plus overscan, retain tokens. Unchanged lines reuse
//// them on selection and scroll updates. Each changed visible line is still
//// scanned in full, so a long minified line costs more than a short line.

import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/syntax/rules.{type Rules}
import glot_frontend/public/editor/code_editor/syntax/scanner.{type LexState}
import glot_frontend/public/editor/code_editor/syntax/token.{type Token}
import glot_frontend/public/editor/code_editor/text

pub type Cache {
  Cache(states: Dict(Int, LexState), lines: Dict(Int, CachedLine), rules: option.Option(Rules))
}

pub type CachedLine {
  CachedLine(text: String, before: LexState, tokens: List(Token), after: LexState)
}

/// One rendered line: its index, its text, and its tokens.
pub type HighlightedLine {
  HighlightedLine(index: Int, text: String, tokens: List(Token))
}

pub fn new() -> Cache {
  Cache(states: dict.new(), lines: dict.new(), rules: option.None)
}

/// Drop everything the edit could have invalidated.
pub fn invalidate_from(cache: Cache, line: Int) -> Cache {
  Cache(
    ..cache,
    states: dict.filter(cache.states, fn(index, _) { index <= line }),
    lines: dict.filter(cache.lines, fn(index, _) { index < line }),
  )
}

/// The state a line starts in, walking back to the newest cached ancestor.
fn nearest_cached(cache: Cache, line: Int) -> #(Int, LexState) {
  case line <= 0 {
    True -> #(0, scanner.Normal)
    False ->
      case dict.get(cache.states, line) {
        Ok(state) -> #(line, state)
        Error(_) -> nearest_cached(cache, line - 1)
      }
  }
}

/// Tokenise lines `[from, to)`, returning the lines and the updated cache.
pub fn lines(
  language_rules: Rules,
  cache: Cache,
  doc: Document,
  from: Int,
  to: Int,
) -> #(List(HighlightedLine), Cache) {
  let from = document.clamp(from, 0, document.line_count(doc))
  let to = document.clamp(to, from, document.line_count(doc))
  let cache = for_rules(cache, language_rules)
  let cache = Cache(..cache, lines: dict.filter(cache.lines, fn(index, _) { index >= from && index < to }))
  let #(start, state) = nearest_cached(cache, from)
  scan_forward(language_rules, cache, doc, start, state, from, to, [])
}

fn scan_forward(
  language_rules: Rules,
  cache: Cache,
  doc: Document,
  index: Int,
  state: LexState,
  from: Int,
  to: Int,
  collected: List(HighlightedLine),
) -> #(List(HighlightedLine), Cache) {
  case index >= to {
    True -> #(list.reverse(collected), cache)
    False -> {
      let text = document.line_text(doc, index)
      let #(tokens, next_state) = case dict.get(cache.lines, index) {
        Ok(cached) if cached.text == text && cached.before == state -> #(cached.tokens, cached.after)
        _ -> scanner.scan_line(language_rules, state, text)
      }
      let cached_lines = case index >= from {
        True -> dict.insert(cache.lines, index, CachedLine(text, state, tokens, next_state))
        False -> cache.lines
      }
      let cache = Cache(..cache, states: dict.insert(cache.states, index + 1, next_state), lines: cached_lines)
      let collected = case index >= from {
        True -> [
          HighlightedLine(index: index, text: text, tokens: tokens),
          ..collected
        ]
        False -> collected
      }
      scan_forward(
        language_rules,
        cache,
        doc,
        index + 1,
        next_state,
        from,
        to,
        collected,
      )
    }
  }
}

/// Re-scan from `line` until the recomputed state matches the cached one, which
/// is the convergence point past which nothing downstream can have changed.
/// `budget` bounds the work one pass may do so a single keystroke can never
/// walk a whole large document.
pub fn converge(
  language_rules: Rules,
  cache: Cache,
  doc: Document,
  line: Int,
  budget: Int,
) -> Cache {
  let cache = for_rules(cache, language_rules)
  let #(start, state) = nearest_cached(cache, line)
  converge_loop(language_rules, cache, doc, start, state, budget)
}

fn converge_loop(
  language_rules: Rules,
  cache: Cache,
  doc: Document,
  index: Int,
  state: LexState,
  budget: Int,
) -> Cache {
  case budget <= 0 || index >= document.line_count(doc) {
    True -> cache
    False -> {
      let #(_, next_state) =
        scanner.scan_line(language_rules, state, document.line_text(doc, index))
      case dict.get(cache.states, index + 1) {
        Ok(cached) if cached == next_state -> cache
        _ ->
          converge_loop(
            language_rules,
            Cache(..cache, states: dict.insert(cache.states, index + 1, next_state)),
            doc,
            index + 1,
            next_state,
            budget - 1,
          )
      }
    }
  }
}

fn for_rules(cache: Cache, rules: Rules) -> Cache {
  case cache.rules {
    option.Some(previous) if previous == rules -> cache
    _ -> Cache(states: dict.new(), lines: dict.new(), rules: option.Some(rules))
  }
}

/// Tokens for one line, ignoring the cache. Used by tests and by the
/// server-rendered fallback.
pub fn line_tokens(
  language_rules: Rules,
  state: LexState,
  text: String,
) -> #(List(Token), LexState) {
  scanner.scan_line(language_rules, state, text)
}

/// Split a line into the substrings each token covers, ready for rendering.
pub fn segments(
  line: String,
  tokens: List(Token),
) -> List(#(token.TokenKind, String)) {
  segments_loop(text.clusters(line), tokens, 0, [])
}

// Tokens are ordered and cover the line. Walk the clusters once instead of
// re-segmenting the full line for every syntax span in minified source.
fn segments_loop(
  clusters: List(text.Cluster),
  tokens: List(Token),
  offset: Int,
  collected: List(#(token.TokenKind, String)),
) -> List(#(token.TokenKind, String)) {
  case tokens {
    [] -> list.reverse(collected)
    [item, ..rest] -> {
      let #(remaining, next, pieces) = segment(clusters, offset, item.start, item.end, [])
      let value = pieces |> list.reverse |> string.join("")
      segments_loop(remaining, rest, next, [#(item.kind, value), ..collected])
    }
  }
}

fn segment(
  clusters: List(text.Cluster),
  offset: Int,
  from: Int,
  to: Int,
  pieces: List(String),
) -> #(List(text.Cluster), Int, List(String)) {
  case clusters {
    [] -> #([], offset, pieces)
    _ if offset >= to -> #(clusters, offset, pieces)
    [first, ..rest] -> {
      let next = offset + first.width
      let pieces = case next <= from {
        True -> pieces
        False -> [first.text, ..pieces]
      }
      segment(rest, next, from, to, pieces)
    }
  }
}


/// Keep syntax spans around the horizontal viewport. Offscreen text stays in
/// the line (so geometry and text content are unchanged), in at most two spans.
/// The lexer still processes the complete line with its language's own rules.
pub fn viewport_tokens(tokens: List(Token), from: Int, to: Int) -> List(Token) {
  let visible = list.filter(tokens, fn(item) { item.end > from && item.start < to })
  case visible, list.last(tokens) {
    [first, ..], Ok(last) -> {
      let prefix = case first.start > 0 {
        True -> [token.Token(token.Plain, 0, first.start)]
        False -> []
      }
      let assert Ok(end) = list.last(visible)
      let suffix = case end.end < last.end {
        True -> [token.Token(token.Plain, end.end, last.end)]
        False -> []
      }
      list.flatten([prefix, visible, suffix])
    }
    [], Ok(last) -> [token.Token(token.Plain, 0, last.end)]
    _, Error(_) -> []
  }
}


pub fn viewport_segments(
  line: String,
  tokens: List(Token),
  first_column: Int,
  last_column: Int,
) -> List(#(token.TokenKind, String)) {
  let clusters = text.clusters(line)
  let tokens = case list.drop(tokens, 1000) {
    [] -> tokens
    _ -> viewport_tokens(
      tokens,
      cluster_offset(clusters, first_column, 0),
      cluster_offset(clusters, last_column, 0),
    )
  }
  segments_loop(clusters, tokens, 0, [])
}

fn cluster_offset(clusters: List(text.Cluster), count: Int, offset: Int) -> Int {
  case clusters {
    [first, ..rest] if count > 0 -> cluster_offset(rest, count - 1, offset + first.width)
    _ -> offset
  }
}
