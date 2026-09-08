//// Lexer rules for the ML, Lisp, and other functional languages.

import glot_frontend/public/editor/code_editor/syntax/rules.{type Rules}

fn make(
  line_comments: List(String),
  block_comments: List(rules.BlockComment),
  strings: List(rules.StringRule),
  keywords: List(String),
  types: List(String),
  literals: List(String),
) -> Rules {
  let base = rules.base()
  rules.Rules(
    ..base,
    line_comments:,
    block_comments:,
    strings:,
    keywords:,
    types:,
    literals:,
  )
}

fn plain_string() -> List(rules.StringRule) {
  [rules.quote("\"", "\"")]
}

/// `#| ... |#` block comments nest in Common Lisp and Scheme.
fn lisp_block() -> List(rules.BlockComment) {
  [rules.BlockComment(open: "#|", close: "|#", nested: True)]
}

fn lisp_identifier_extra() -> List(String) {
  ["-", "*", "+", "/", "<", ">", "=", "?", "!", ".", ":", "%", "&", "^", "~"]
}

pub fn clisp() -> Rules {
  let base =
    make(
      [";"],
      lisp_block(),
      plain_string(),
      [
        "defun", "defmacro", "defparameter", "defvar", "defconstant",
        "defstruct", "defclass", "defmethod", "defgeneric", "defpackage",
        "in-package", "let", "let*", "labels", "flet", "macrolet", "lambda",
        "if", "when", "unless", "cond", "case", "typecase", "loop", "do",
        "do*", "dolist", "dotimes", "progn", "prog1", "prog2", "block",
        "return", "return-from", "setf", "setq", "quote", "function",
        "multiple-value-bind", "destructuring-bind", "handler-case", "unwind-protect",
        "declare", "declaim", "the", "eval-when", "and", "or", "not",
      ],
      [
        "integer", "fixnum", "bignum", "ratio", "float", "double-float",
        "single-float", "complex", "character", "string", "symbol", "keyword",
        "list", "cons", "vector", "array", "hash-table", "stream", "function",
        "pathname", "sequence",
      ],
      ["t", "nil"],
    )
  rules.Rules(
    ..base,
    identifier_extra: lisp_identifier_extra(),
    identifier_start_extra: ["*", "+", "-", "/", "<", ">", "="],
    call_highlighting: False,
  )
}

pub fn guile() -> Rules {
  let base =
    make(
      [";"],
      lisp_block(),
      plain_string(),
      [
        "define", "define-syntax", "define-record-type", "define-module",
        "define-public", "define-values", "lambda", "let", "let*", "letrec",
        "letrec*", "let-values", "named-let", "if", "cond", "case", "when",
        "unless", "and", "or", "not", "begin", "do", "delay", "force",
        "quasiquote", "quote", "unquote", "set!", "else", "use-modules",
        "call-with-current-continuation", "call/cc", "dynamic-wind", "syntax-rules",
      ],
      [
        "boolean?", "char?", "number?", "pair?", "procedure?", "string?",
        "symbol?", "vector?", "list?", "null?", "integer?", "rational?",
        "real?", "exact?", "inexact?",
      ],
      ["#t", "#f", "else"],
    )
  rules.Rules(
    ..base,
    identifier_extra: lisp_identifier_extra(),
    identifier_start_extra: ["*", "+", "-", "/", "<", ">", "="],
    call_highlighting: False,
  )
}

pub fn clojure() -> Rules {
  let base =
    make(
      [";"],
      [],
      plain_string(),
      [
        "def", "defn", "defn-", "defmacro", "defmulti", "defmethod",
        "defprotocol", "defrecord", "deftype", "definterface", "defstruct",
        "ns", "fn", "let", "letfn", "loop", "recur", "if", "if-let",
        "if-some", "if-not", "when", "when-let", "when-some", "when-not",
        "cond", "condp", "case", "do", "doseq", "dotimes", "for", "while",
        "try", "catch", "finally", "throw", "quote", "var", "set!", "new",
        "monitor-enter", "monitor-exit", "binding", "with-open",
        "with-local-vars", "require", "import", "in-ns", "and", "or", "not",
      ],
      [
        "boolean", "byte", "char", "double", "float", "int", "long", "short",
        "String", "Object", "Number", "Integer", "Boolean", "Keyword",
        "Symbol", "PersistentVector", "PersistentList", "PersistentHashMap",
      ],
      ["nil", "true", "false"],
    )
  rules.Rules(
    ..base,
    identifier_extra: lisp_identifier_extra(),
    identifier_start_extra: ["*", "+", "-", "/", "<", ">", "=", "&"],
    call_highlighting: False,
    meta_prefixes: ["#_", "#'", "::"],
  )
}

pub fn elixir() -> Rules {
  let base =
    make(
      ["#"],
      [],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.raw_multiline_quote("'''", "'''"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "after", "alias", "and", "case", "catch", "cond", "def", "defdelegate",
        "defexception", "defguard", "defimpl", "defmacro", "defmacrop",
        "defmodule", "defoverridable", "defp", "defprotocol", "defstruct",
        "do", "else", "end", "fn", "for", "if", "import", "in", "not", "or",
        "quote", "raise", "receive", "require", "rescue", "throw", "try",
        "unless", "unquote", "use", "when", "with",
      ],
      [
        "Atom", "Enum", "Float", "Integer", "Keyword", "List", "Map",
        "MapSet", "Module", "Process", "Range", "Stream", "String", "Task",
        "Tuple", "Agent", "GenServer", "Supervisor",
      ],
      ["nil", "true", "false"],
    )
  rules.Rules(
    ..base,
    identifier_extra: ["?", "!"],
    meta_prefixes: ["@"],
    capitalized_types: True,
  )
}

pub fn elm() -> Rules {
  let base =
    make(
      ["--"],
      [rules.BlockComment(open: "{-", close: "-}", nested: True)],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "module", "exposing", "import", "as", "type", "alias", "port", "if",
        "then", "else", "case", "of", "let", "in", "infix", "infixl", "infixr",
      ],
      [
        "Int", "Float", "Bool", "Char", "String", "List", "Maybe", "Result",
        "Cmd", "Sub", "Program", "Html", "Attribute", "Order", "Dict", "Set",
        "Array",
      ],
      ["True", "False", "Nothing", "Just", "Ok", "Err"],
    )
  rules.Rules(..base, capitalized_types: True, call_highlighting: False)
}

pub fn erlang() -> Rules {
  let base =
    make(
      ["%"],
      [],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "after", "and", "andalso", "band", "begin", "bnot", "bor", "bsl",
        "bsr", "bxor", "case", "catch", "cond", "div", "end", "fun", "if",
        "let", "not", "of", "or", "orelse", "receive", "rem", "try", "when",
        "xor", "maybe", "else",
      ],
      [
        "atom", "binary", "bitstring", "boolean", "float", "function",
        "integer", "list", "map", "number", "pid", "port", "reference",
        "tuple", "term", "any", "none", "no_return", "iodata", "iolist",
      ],
      ["true", "false", "undefined", "ok", "error"],
    )
  rules.Rules(..base, meta_prefixes: ["-module", "-export", "-import", "-spec",
    "-type", "-record", "-define", "-include", "-behaviour", "-compile"],
    identifier_extra: ["@"])
}

pub fn fsharp() -> Rules {
  let base =
    make(
      ["//"],
      [rules.BlockComment(open: "(*", close: "*)", nested: True)],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "abstract", "and", "as", "assert", "base", "begin", "class", "default",
        "delegate", "do", "done", "downcast", "downto", "elif", "else", "end",
        "exception", "extern", "finally", "fixed", "for", "fun", "function",
        "global", "if", "in", "inherit", "inline", "interface", "internal",
        "lazy", "let", "match", "member", "module", "mutable", "namespace",
        "new", "of", "open", "or", "override", "private", "public", "rec",
        "return", "select", "static", "struct", "then", "to", "try", "type",
        "upcast", "use", "val", "void", "when", "while", "with", "yield",
      ],
      [
        "bool", "byte", "char", "decimal", "double", "float", "float32",
        "int", "int8", "int16", "int32", "int64", "list", "obj", "option",
        "sbyte", "seq", "single", "string", "uint", "uint16", "uint32",
        "uint64", "unit", "array", "Map", "Set", "Async",
      ],
      ["null", "true", "false", "None", "Some"],
    )
  rules.Rules(..base, meta_prefixes: ["#", "[<"], capitalized_types: True)
}

pub fn haskell() -> Rules {
  let base =
    make(
      ["--"],
      [rules.BlockComment(open: "{-", close: "-}", nested: True)],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "case", "class", "data", "default", "deriving", "do", "else",
        "foreign", "if", "import", "in", "infix", "infixl", "infixr",
        "instance", "let", "module", "newtype", "of", "then", "type", "where",
        "forall", "mdo", "proc", "rec", "family", "pattern",
      ],
      [
        "Bool", "Char", "Double", "Either", "Float", "Int", "Integer", "IO",
        "Maybe", "Ordering", "Rational", "String", "Word", "Map", "Set",
        "Text", "Monad", "Functor", "Applicative", "Foldable", "Traversable",
      ],
      ["True", "False", "Nothing", "Just", "Left", "Right", "otherwise"],
    )
  rules.Rules(
    ..base,
    meta_prefixes: ["{-#"],
    identifier_extra: ["'"],
    capitalized_types: True,
    call_highlighting: False,
  )
}

pub fn idris() -> Rules {
  let base =
    make(
      ["--"],
      [rules.BlockComment(open: "{-", close: "-}", nested: True)],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "auto", "case", "class", "data", "do", "dsl", "else", "export",
        "if", "impossible", "implementation", "implicit", "import", "in",
        "infix", "infixl", "infixr", "instance", "interface", "let", "module",
        "mutual", "namespace", "of", "parameters", "partial", "postulate",
        "private", "proof", "public", "record", "rewrite", "syntax", "then",
        "total", "using", "where", "with", "covering",
      ],
      [
        "Bool", "Char", "Double", "Either", "Int", "Integer", "IO", "List",
        "Maybe", "Nat", "String", "Type", "Unit", "Vect", "Void",
      ],
      ["True", "False", "Nothing", "Just", "Left", "Right", "Z", "S"],
    )
  rules.Rules(
    ..base,
    identifier_extra: ["'"],
    capitalized_types: True,
    call_highlighting: False,
  )
}

pub fn ocaml() -> Rules {
  let base =
    make(
      [],
      [rules.BlockComment(open: "(*", close: "*)", nested: True)],
      [
        rules.multiline_quote("{|", "|}"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "and", "as", "assert", "asr", "begin", "class", "constraint", "do",
        "done", "downto", "else", "end", "exception", "external", "for", "fun",
        "function", "functor", "if", "in", "include", "inherit", "initializer",
        "land", "lazy", "let", "lor", "lsl", "lsr", "lxor", "match", "method",
        "mod", "module", "mutable", "new", "nonrec", "object", "of", "open",
        "or", "private", "rec", "sig", "struct", "then", "to", "try", "type",
        "val", "virtual", "when", "while", "with",
      ],
      [
        "array", "bool", "bytes", "char", "exn", "float", "format", "int",
        "int32", "int64", "lazy_t", "list", "nativeint", "option", "ref",
        "result", "string", "unit", "Hashtbl", "Map", "Set", "Buffer",
      ],
      ["true", "false", "None", "Some"],
    )
  rules.Rules(
    ..base,
    identifier_extra: ["'"],
    capitalized_types: True,
  )
}

pub fn mercury() -> Rules {
  let base =
    make(
      ["%"],
      [rules.BlockComment(open: "/*", close: "*/", nested: False)],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "module", "interface", "implementation", "import_module", "use_module",
        "include_module", "end_module", "type", "pred", "func", "mode", "inst",
        "typeclass", "instance", "pragma", "promise", "initialise",
        "finalise", "mutable", "is", "some", "all", "if", "then", "else",
        "not", "fail", "true", "semidet", "det", "nondet", "multi", "erroneous",
        "cc_multi", "cc_nondet", "failure", "in", "out", "di", "uo",
      ],
      [
        "int", "float", "char", "string", "bool", "list", "map", "set",
        "array", "io", "univ", "maybe", "pair", "assoc_list",
      ],
      ["yes", "no"],
    )
  rules.Rules(..base, identifier_extra: ["'"], capitalized_types: True)
}

pub fn nix() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "/*", close: "*/", nested: False)],
      [
        rules.raw_multiline_quote("''", "''"),
        rules.quote("\"", "\""),
      ],
      [
        "assert", "else", "if", "in", "inherit", "let", "or", "rec", "then",
        "with", "import",
      ],
      [
        "builtins", "derivation", "fetchTarball", "fetchGit", "map", "toString",
        "removeAttrs", "abort", "throw",
      ],
      ["true", "false", "null"],
    )
  rules.Rules(..base, identifier_extra: ["-", "'"])
}

pub fn julia() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "#=", close: "=#", nested: True)],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
        rules.raw_multiline_quote("`", "`"),
      ],
      [
        "abstract type", "baremodule", "begin", "break", "catch", "const",
        "continue", "do", "else", "elseif", "end", "export", "finally", "for",
        "function", "global", "if", "import", "let", "local", "macro",
        "module", "mutable", "primitive", "quote", "return", "struct", "try",
        "type", "using", "where", "while", "in", "isa",
      ],
      [
        "Any", "Array", "Bool", "Char", "Complex", "Dict", "Float16",
        "Float32", "Float64", "Function", "Int", "Int8", "Int16", "Int32",
        "Int64", "Integer", "Number", "Nothing", "Rational", "Real", "Set",
        "String", "Symbol", "Tuple", "UInt", "Union", "Vector", "Matrix",
      ],
      ["true", "false", "nothing", "missing", "NaN", "Inf", "pi",
      ],
    )
  rules.Rules(
    ..base,
    meta_prefixes: ["@"],
    identifier_extra: ["!"],
    capitalized_types: True,
  )
}
