//// Highlighting tokens.
////
//// The kinds map onto the syntax custom properties the theme already defines
//// (`--syntax-keyword`, `--syntax-string`, `--syntax-number`,
//// `--syntax-function`, `--syntax-type`) plus the muted and subtle text colours
//// the old CodeMirror highlight style used for variables, operators, and
//// comments. No new theme tokens are introduced.

pub type TokenKind {
  Plain
  Keyword
  TypeName
  FunctionName
  StringLiteral
  NumberLiteral
  Comment
  Operator
  Meta
}

/// A token covering `[start, end)` in UTF-16 offsets inside one line.
pub type Token {
  Token(kind: TokenKind, start: Int, end: Int)
}

/// The CSS class rendered for a token. `syntax` styles live in `editor.css`.
pub fn class_name(kind: TokenKind) -> String {
  case kind {
    Plain -> "code-editor__token"
    Keyword -> "code-editor__token code-editor__token--keyword"
    TypeName -> "code-editor__token code-editor__token--type"
    FunctionName -> "code-editor__token code-editor__token--function"
    StringLiteral -> "code-editor__token code-editor__token--string"
    NumberLiteral -> "code-editor__token code-editor__token--number"
    Comment -> "code-editor__token code-editor__token--comment"
    Operator -> "code-editor__token code-editor__token--operator"
    Meta -> "code-editor__token code-editor__token--meta"
  }
}
