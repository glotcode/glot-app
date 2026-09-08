//// Lexer rules for the scripting languages.

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

pub fn bash() -> Rules {
  let base =
    make(
      ["#"],
      [],
      [
        rules.quote("\"", "\""),
        rules.StringRule(
          open: "'",
          close: "'",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
      ],
      [
        "if", "then", "elif", "else", "fi", "case", "esac", "for", "select",
        "while", "until", "do", "done", "in", "function", "time", "coproc",
        "return", "break", "continue", "local", "export", "readonly",
        "declare", "typeset", "unset", "shift", "source", "alias", "unalias",
        "set", "trap", "exec", "eval", "exit",
      ],
      [
        "echo", "printf", "read", "cd", "pwd", "test", "true", "false", "let",
        "mapfile", "readarray", "getopts", "command", "builtin", "type",
      ],
      ["true", "false"],
    )
  rules.Rules(
    ..base,
    identifier_start_extra: ["$"],
    identifier_extra: ["$", "-"],
    heredocs: True,
    call_highlighting: False,
  )
}

pub fn coffeescript() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "###", close: "###", nested: False)],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.raw_multiline_quote("'''", "'''"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "and", "await", "break", "by", "case", "catch", "class", "continue",
        "debugger", "delete", "do", "else", "extends", "finally", "for",
        "if", "in", "instanceof", "is", "isnt", "loop", "new", "not", "of",
        "or", "own", "return", "super", "switch", "then", "this", "throw",
        "try", "typeof", "unless", "until", "when", "while", "yield",
      ],
      [
        "Array", "Boolean", "Date", "Error", "Function", "JSON", "Math",
        "Number", "Object", "RegExp", "String",
      ],
      ["null", "undefined", "true", "false", "yes", "no", "on", "off"],
    )
  rules.Rules(..base, identifier_start_extra: ["$", "@"], identifier_extra: ["$"])
}

pub fn crystal() -> Rules {
  let base =
    make(
      ["#"],
      [],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "abstract", "alias", "annotation", "as", "asm", "begin", "break",
        "case", "class", "def", "do", "else", "elsif", "end", "ensure",
        "enum", "extend", "for", "fun", "if", "in", "include", "instance_sizeof",
        "is_a?", "lib", "macro", "module", "next", "of", "out", "pointerof",
        "private", "protected", "require", "rescue", "return", "select",
        "self", "sizeof", "struct", "super", "then", "type", "typeof",
        "union", "unless", "until", "verbatim", "when", "while", "with",
        "yield", "uninitialized",
      ],
      [
        "Array", "Bool", "Char", "Float32", "Float64", "Hash", "Int8",
        "Int16", "Int32", "Int64", "Nil", "Number", "Object", "Proc",
        "Range", "Set", "String", "Symbol", "Tuple", "UInt8", "UInt32",
        "UInt64", "Void",
      ],
      ["nil", "true", "false"],
    )
  rules.Rules(
    ..base,
    identifier_extra: ["?", "!"],
    identifier_start_extra: ["@", "$"],
    heredocs: True,
    capitalized_types: True,
  )
}

pub fn lua() -> Rules {
  make(
      ["--"],
      [rules.BlockComment(open: "--[[", close: "]]", nested: False)],
      [
        rules.raw_multiline_quote("[[", "]]"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "and", "break", "do", "else", "elseif", "end", "false", "for",
        "function", "goto", "if", "in", "local", "nil", "not", "or", "repeat",
        "return", "then", "true", "until", "while",
      ],
      [
        "string", "table", "math", "io", "os", "coroutine", "debug", "utf8",
        "package",
      ],
    ["nil", "true", "false"],
  )
}

pub fn nim() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "#[", close: "]#", nested: True)],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast",
        "concept", "const", "continue", "converter", "defer", "discard",
        "distinct", "div", "do", "elif", "else", "end", "enum", "except",
        "export", "finally", "for", "from", "func", "if", "import", "in",
        "include", "interface", "is", "isnot", "iterator", "let", "macro",
        "method", "mixin", "mod", "nil", "not", "notin", "object", "of", "or",
        "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr",
        "static", "template", "try", "tuple", "type", "using", "var", "when",
        "while", "xor", "yield",
      ],
      [
        "bool", "byte", "char", "cstring", "float", "float32", "float64",
        "int", "int8", "int16", "int32", "int64", "string", "uint", "uint8",
        "uint16", "uint32", "uint64", "seq", "array", "openArray", "Table",
        "HashSet",
      ],
      ["true", "false", "nil"],
    )
  rules.Rules(..base, meta_prefixes: ["{.", "."], capitalized_types: True)
}

pub fn perl() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "=pod", close: "=cut", nested: False)],
      [
        rules.quote("\"", "\""),
        rules.StringRule(
          open: "'",
          close: "'",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
      ],
      [
        "and", "bless", "break", "continue", "cmp", "do", "else", "elsif",
        "eq", "eval", "exit", "for", "foreach", "ge", "given", "goto", "gt",
        "if", "last", "le", "local", "lt", "my", "ne", "next", "no", "not",
        "or", "our", "package", "redo", "require", "return", "state", "sub",
        "unless", "until", "use", "wantarray", "when", "while", "xor",
      ],
      [
        "chomp", "chop", "defined", "delete", "die", "each", "exists", "grep",
        "join", "keys", "length", "map", "pop", "print", "printf", "push",
        "ref", "reverse", "scalar", "shift", "sort", "splice", "split",
        "sprintf", "unshift", "values", "warn",
      ],
      ["undef"],
    )
  rules.Rules(
    ..base,
    identifier_start_extra: ["$", "@", "%", "&"],
    identifier_extra: ["$", ":"],
    heredocs: True,
  )
}

pub fn python() -> Rules {
  let base =
    make(
      ["#"],
      [],
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.raw_multiline_quote("'''", "'''"),
        rules.quote("f\"", "\""),
        rules.quote("r\"", "\""),
        rules.quote("b\"", "\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "and", "as", "assert", "async", "await", "break", "class", "continue",
        "def", "del", "elif", "else", "except", "finally", "for", "from",
        "global", "if", "import", "in", "is", "lambda", "match", "nonlocal",
        "not", "or", "pass", "raise", "return", "try", "while", "with",
        "yield", "case",
      ],
      [
        "bool", "bytes", "complex", "dict", "float", "frozenset", "int",
        "list", "object", "set", "str", "tuple", "type", "bytearray",
        "memoryview", "range",
      ],
      ["None", "True", "False", "NotImplemented", "Ellipsis"],
    )
  rules.Rules(..base, meta_prefixes: ["@"], capitalized_types: False)
}

pub fn raku() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "=begin", close: "=end", nested: False)],
      [
        rules.quote("\"", "\""),
        rules.StringRule(
          open: "'",
          close: "'",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
      ],
      [
        "and", "andthen", "augment", "but", "class", "constant", "default",
        "do", "does", "else", "elsif", "enum", "for", "gather", "given",
        "grammar", "has", "if", "import", "is", "role", "return", "state",
        "sub", "submethod", "subset", "supply", "take", "try", "unit",
        "unless", "until", "use", "when", "while", "with", "without", "my",
        "our", "let", "loop", "multi", "need", "next", "last", "redo",
        "proto", "only", "react", "whenever", "start", "orwith", "or", "not",
      ],
      [
        "Any", "Array", "Bool", "Complex", "Cool", "Date", "DateTime", "Hash",
        "Int", "Junction", "List", "Map", "Mu", "Num", "Numeric", "Pair",
        "Range", "Rat", "Seq", "Set", "Str", "Supply", "Version",
      ],
      ["True", "False", "Nil", "Inf", "NaN"],
    )
  rules.Rules(
    ..base,
    identifier_start_extra: ["$", "@", "%", "&"],
    identifier_extra: ["-", "'"],
    heredocs: True,
    capitalized_types: True,
  )
}

pub fn ruby() -> Rules {
  let base =
    make(
      ["#"],
      [rules.BlockComment(open: "=begin", close: "=end", nested: False)],
      [
        rules.quote("\"", "\""),
        rules.StringRule(
          open: "'",
          close: "'",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
        rules.raw_multiline_quote("%w(", ")"),
        rules.raw_multiline_quote("%i(", ")"),
      ],
      [
        "alias", "and", "begin", "break", "case", "class", "def", "defined?",
        "do", "else", "elsif", "end", "ensure", "for", "if", "in", "module",
        "next", "not", "or", "redo", "rescue", "retry", "return", "self",
        "super", "then", "undef", "unless", "until", "when", "while",
        "yield", "lambda", "proc", "require", "require_relative", "include",
        "extend", "attr_accessor", "attr_reader", "attr_writer",
      ],
      [
        "Array", "Comparable", "Enumerable", "Exception", "File", "Float",
        "Hash", "Integer", "IO", "Kernel", "Module", "Numeric", "Object",
        "Proc", "Range", "Regexp", "String", "Struct", "Symbol", "Time",
      ],
      ["nil", "true", "false", "__FILE__", "__LINE__"],
    )
  rules.Rules(
    ..base,
    identifier_extra: ["?", "!"],
    identifier_start_extra: ["@", "$", ":"],
    heredocs: True,
    capitalized_types: True,
  )
}
