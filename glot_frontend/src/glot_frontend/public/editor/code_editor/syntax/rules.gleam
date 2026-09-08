//// Language-specific lexer rules.
////
//// Each supported language supplies its own `Rules` value; the shared scanner
//// in `syntax/scanner` turns those rules into tokens. Splitting the rules from
//// the scanning primitives is what lets 44 languages share one incremental,
//// state-caching lexer without any of them falling back to a generic mode.

/// A block comment. `nested` is true for languages whose block comments nest,
/// such as Rust, Haskell, D, OCaml, and F#.
pub type BlockComment {
  BlockComment(open: String, close: String, nested: Bool)
}

/// A quoted form. `multiline` marks delimiters that may span lines, which is
/// what turns the lexer into a stateful one.
pub type StringRule {
  StringRule(
    open: String,
    close: String,
    escape: Bool,
    multiline: Bool,
    interpolation: Bool,
  )
}

pub type Rules {
  Rules(
    /// False only for Plaintext, which is rendered without highlighting.
    highlights: Bool,
    /// Comment tokens, also used by the comment-toggling command.
    line_comments: List(String),
    block_comments: List(BlockComment),
    strings: List(StringRule),
    keywords: List(String),
    types: List(String),
    literals: List(String),
    /// Prefixes that mark a whole token as meta: preprocessor lines,
    /// annotations, attributes, pragmas.
    meta_prefixes: List(String),
    /// Characters that may appear in an identifier besides letters, digits and
    /// `_`, such as Lisp's `-`, Ruby's trailing `?`, or Perl's sigils.
    identifier_extra: List(String),
    /// Characters that may *start* an identifier besides letters and `_`.
    identifier_start_extra: List(String),
    /// True when `Capitalised` identifiers should be highlighted as types.
    capitalized_types: Bool,
    /// True when an identifier immediately followed by `(` is a call.
    call_highlighting: Bool,
    /// Shell/Perl/Ruby style `<<EOF` heredocs.
    heredocs: Bool,
    /// Cobol and fixed-format Fortran style: a marker in an early column
    /// comments the whole line.
    fixed_format_comment_column: Bool,
  )
}

/// A rules value with everything switched off, used as the base each language
/// customises so that adding a field cannot silently change 44 languages.
pub fn base() -> Rules {
  Rules(
    highlights: True,
    line_comments: [],
    block_comments: [],
    strings: [],
    keywords: [],
    types: [],
    literals: [],
    meta_prefixes: [],
    identifier_extra: [],
    identifier_start_extra: [],
    capitalized_types: False,
    call_highlighting: True,
    heredocs: False,
    fixed_format_comment_column: False,
  )
}

/// Rules for a language that is rendered as plain text.
pub fn plain() -> Rules {
  Rules(..base(), highlights: False)
}

/// Double and single quoted strings with backslash escapes, the shape shared by
/// most C-like and scripting languages.
pub fn common_quotes() -> List(StringRule) {
  [
    StringRule(
      open: "\"",
      close: "\"",
      escape: True,
      multiline: False,
      interpolation: False,
    ),
    StringRule(
      open: "'",
      close: "'",
      escape: True,
      multiline: False,
      interpolation: False,
    ),
  ]
}

pub fn quote(open: String, close: String) -> StringRule {
  StringRule(
    open: open,
    close: close,
    escape: True,
    multiline: False,
    interpolation: False,
  )
}

pub fn multiline_quote(open: String, close: String) -> StringRule {
  StringRule(
    open: open,
    close: close,
    escape: True,
    multiline: True,
    interpolation: False,
  )
}

pub fn raw_multiline_quote(open: String, close: String) -> StringRule {
  StringRule(
    open: open,
    close: close,
    escape: False,
    multiline: True,
    interpolation: False,
  )
}

pub fn slash_comments() -> #(List(String), List(BlockComment)) {
  #(["//"], [BlockComment(open: "/*", close: "*/", nested: False)])
}
