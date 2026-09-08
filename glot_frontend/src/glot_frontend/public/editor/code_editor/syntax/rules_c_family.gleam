//// Lexer rules for the C-family and other brace languages.

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

fn slash_block() -> List(rules.BlockComment) {
  [rules.BlockComment(open: "/*", close: "*/", nested: False)]
}

fn nested_slash_block() -> List(rules.BlockComment) {
  [rules.BlockComment(open: "/*", close: "*/", nested: True)]
}

pub fn c() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      rules.common_quotes(),
      [
        "auto", "break", "case", "const", "continue", "default", "do", "else",
        "enum", "extern", "for", "goto", "if", "inline", "register", "restrict",
        "return", "sizeof", "static", "struct", "switch", "typedef", "union",
        "volatile", "while", "_Alignas", "_Alignof", "_Atomic", "_Generic",
        "_Noreturn", "_Static_assert", "_Thread_local",
      ],
      [
        "char", "double", "float", "int", "long", "short", "signed", "unsigned",
        "void", "size_t", "ssize_t", "ptrdiff_t", "wchar_t", "bool", "_Bool",
        "_Complex", "_Imaginary", "int8_t", "int16_t", "int32_t", "int64_t",
        "uint8_t", "uint16_t", "uint32_t", "uint64_t", "intptr_t", "uintptr_t",
        "FILE", "va_list",
      ],
      ["NULL", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["#"])
}

pub fn cpp() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      rules.common_quotes(),
      [
        "alignas", "alignof", "and", "asm", "auto", "break", "case", "catch",
        "class", "co_await", "co_return", "co_yield", "concept", "const",
        "consteval", "constexpr", "constinit", "const_cast", "continue",
        "decltype", "default", "delete", "do", "dynamic_cast", "else", "enum",
        "explicit", "export", "extern", "for", "friend", "goto", "if", "inline",
        "mutable", "namespace", "new", "noexcept", "not", "operator", "or",
        "private", "protected", "public", "register", "reinterpret_cast",
        "requires", "return", "sizeof", "static", "static_assert",
        "static_cast", "struct", "switch", "template", "this", "thread_local",
        "throw", "try", "typedef", "typeid", "typename", "union", "using",
        "virtual", "volatile", "while", "xor",
      ],
      [
        "bool", "char", "char8_t", "char16_t", "char32_t", "double", "float",
        "int", "long", "short", "signed", "unsigned", "void", "wchar_t",
        "size_t", "string", "wstring", "vector", "map", "unordered_map", "set",
        "unordered_set", "pair", "tuple", "array", "deque", "list", "optional",
        "variant", "shared_ptr", "unique_ptr", "weak_ptr", "ostream", "istream",
        "stringstream",
      ],
      ["nullptr", "true", "false", "NULL"],
    )
  rules.Rules(..base, meta_prefixes: ["#"])
}

pub fn csharp() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      [
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
        rules.raw_multiline_quote("@\"", "\""),
        rules.quote("$\"", "\""),
      ],
      [
        "abstract", "as", "async", "await", "base", "break", "case", "catch",
        "checked", "class", "const", "continue", "default", "delegate", "do",
        "else", "enum", "event", "explicit", "extern", "finally", "fixed",
        "for", "foreach", "goto", "if", "implicit", "in", "interface",
        "internal", "is", "lock", "namespace", "new", "operator", "out",
        "override", "params", "private", "protected", "public", "readonly",
        "record", "ref", "return", "sealed", "sizeof", "stackalloc", "static",
        "struct", "switch", "this", "throw", "try", "typeof", "unchecked",
        "unsafe", "using", "var", "virtual", "volatile", "when", "where",
        "while", "yield", "get", "set", "init", "nameof",
      ],
      [
        "bool", "byte", "char", "decimal", "double", "dynamic", "float", "int",
        "long", "object", "sbyte", "short", "string", "uint", "ulong",
        "ushort", "void", "List", "Dictionary", "IEnumerable", "Task",
        "Console", "String",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["#"], capitalized_types: True)
}

pub fn d() -> Rules {
  let base =
    make(
      ["//"],
      [
        rules.BlockComment(open: "/*", close: "*/", nested: False),
        rules.BlockComment(open: "/+", close: "+/", nested: True),
      ],
      [
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
        rules.raw_multiline_quote("`", "`"),
      ],
      [
        "abstract", "alias", "align", "asm", "assert", "auto", "body", "break",
        "case", "cast", "catch", "class", "const", "continue", "debug",
        "default", "delegate", "delete", "deprecated", "do", "else", "enum",
        "export", "extern", "final", "finally", "for", "foreach",
        "foreach_reverse", "function", "goto", "if", "immutable", "import",
        "in", "inout", "interface", "invariant", "is", "lazy", "macro",
        "mixin", "module", "new", "nothrow", "out", "override", "package",
        "pragma", "private", "protected", "public", "pure", "ref", "return",
        "scope", "shared", "static", "struct", "super", "switch",
        "synchronized", "template", "this", "throw", "try", "typeid", "typeof",
        "union", "unittest", "version", "while", "with",
      ],
      [
        "bool", "byte", "cdouble", "cent", "cfloat", "char", "creal", "dchar",
        "double", "float", "idouble", "ifloat", "int", "ireal", "long", "real",
        "short", "size_t", "string", "ubyte", "ucent", "uint", "ulong",
        "ushort", "void", "wchar",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, capitalized_types: True)
}

pub fn dart() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.raw_multiline_quote("'''", "'''"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "abstract", "as", "assert", "async", "await", "base", "break", "case",
        "catch", "class", "const", "continue", "covariant", "default",
        "deferred", "do", "else", "enum", "export", "extends", "extension",
        "external", "factory", "final", "finally", "for", "get", "hide", "if",
        "implements", "import", "in", "interface", "is", "late", "library",
        "mixin", "new", "on", "operator", "part", "required", "rethrow",
        "return", "sealed", "set", "show", "static", "super", "switch", "sync",
        "this", "throw", "try", "typedef", "var", "when", "while", "with",
        "yield",
      ],
      [
        "bool", "double", "dynamic", "int", "num", "String", "List", "Map",
        "Set", "Future", "Stream", "Object", "void", "Iterable",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["@"], capitalized_types: True)
}

pub fn go() -> Rules {
  make(
    ["//"],
    slash_block(),
    [
      rules.quote("\"", "\""),
      rules.quote("'", "'"),
      rules.raw_multiline_quote("`", "`"),
    ],
    [
      "break", "case", "chan", "const", "continue", "default", "defer", "else",
      "fallthrough", "for", "func", "go", "goto", "if", "import", "interface",
      "map", "package", "range", "return", "select", "struct", "switch",
      "type", "var",
    ],
    [
      "bool", "byte", "complex64", "complex128", "error", "float32", "float64",
      "int", "int8", "int16", "int32", "int64", "rune", "string", "uint",
      "uint8", "uint16", "uint32", "uint64", "uintptr", "any",
    ],
    ["nil", "true", "false", "iota"],
  )
}

pub fn groovy() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.raw_multiline_quote("'''", "'''"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "abstract", "as", "assert", "break", "case", "catch", "class", "const",
        "continue", "def", "default", "do", "else", "enum", "extends", "final",
        "finally", "for", "goto", "if", "implements", "import", "in",
        "instanceof", "interface", "native", "new", "package", "private",
        "protected", "public", "return", "static", "strictfp", "super",
        "switch", "synchronized", "this", "throw", "throws", "trait",
        "transient", "try", "volatile", "while",
      ],
      [
        "boolean", "byte", "char", "double", "float", "int", "long", "short",
        "void", "String", "List", "Map", "Set", "Object", "BigDecimal",
        "BigInteger",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["@"], capitalized_types: True)
}

pub fn hare() -> Rules {
  let base =
    make(
      ["//"],
      [],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "as", "break", "case", "const", "continue", "def", "defer", "else",
        "export", "fn", "for", "if", "is", "let", "match", "return", "static",
        "struct", "switch", "type", "union", "use", "yield", "alloc", "append",
        "assert", "delete", "free", "insert", "len", "offset", "abort",
      ],
      [
        "bool", "f32", "f64", "i8", "i16", "i32", "i64", "int", "rune", "str",
        "u8", "u16", "u32", "u64", "uint", "uintptr", "size", "valist", "void",
        "nullable",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["@"])
}

pub fn java() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "abstract", "assert", "break", "case", "catch", "class", "const",
        "continue", "default", "do", "else", "enum", "extends", "final",
        "finally", "for", "goto", "if", "implements", "import", "instanceof",
        "interface", "native", "new", "package", "private", "protected",
        "public", "record", "return", "sealed", "static", "strictfp", "super",
        "switch", "synchronized", "this", "throw", "throws", "transient",
        "try", "var", "volatile", "while", "yield", "permits",
      ],
      [
        "boolean", "byte", "char", "double", "float", "int", "long", "short",
        "void", "String", "Object", "Integer", "Double", "Boolean", "List",
        "Map", "Set", "ArrayList", "HashMap", "System", "Exception",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["@"], capitalized_types: True)
}

pub fn javascript() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      [
        rules.raw_multiline_quote("`", "`"),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "async", "await", "break", "case", "catch", "class", "const",
        "continue", "debugger", "default", "delete", "do", "else", "export",
        "extends", "finally", "for", "from", "function", "get", "if", "import",
        "in", "instanceof", "let", "new", "of", "return", "set", "static",
        "super", "switch", "this", "throw", "try", "typeof", "var", "void",
        "while", "with", "yield",
      ],
      [
        "Array", "Boolean", "Date", "Error", "Function", "JSON", "Map", "Math",
        "Number", "Object", "Promise", "RegExp", "Set", "String", "Symbol",
        "WeakMap", "WeakSet", "BigInt",
      ],
      ["null", "undefined", "true", "false", "NaN", "Infinity"],
    )
  rules.Rules(..base, identifier_start_extra: ["$"], identifier_extra: ["$"])
}

pub fn typescript() -> Rules {
  let base = javascript()
  rules.Rules(
    ..base,
    keywords: [
      "abstract", "as", "declare", "enum", "implements", "interface", "is",
      "keyof", "namespace", "override", "private", "protected", "public",
      "readonly", "satisfies", "type",
      ..base.keywords
    ],
    types: [
      "any", "bigint", "boolean", "never", "number", "object", "string",
      "symbol", "unknown", "void", "Partial", "Record", "Readonly", "Required",
      ..base.types
    ],
  )
}

pub fn kotlin() -> Rules {
  let base =
    make(
      ["//"],
      nested_slash_block(),
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "actual", "abstract", "annotation", "as", "break", "by", "catch",
        "class", "companion", "const", "constructor", "continue", "crossinline",
        "data", "do", "dynamic", "else", "enum", "expect", "external", "field",
        "final", "finally", "for", "fun", "get", "if", "import", "in", "infix",
        "init", "inline", "inner", "interface", "internal", "is", "lateinit",
        "noinline", "object", "open", "operator", "out", "override", "package",
        "private", "protected", "public", "reified", "return", "sealed", "set",
        "super", "suspend", "tailrec", "this", "throw", "try", "typealias",
        "typeof", "val", "var", "vararg", "when", "where", "while",
      ],
      [
        "Any", "Array", "Boolean", "Byte", "Char", "Double", "Float", "Int",
        "List", "Long", "Map", "Nothing", "Number", "Set", "Short", "String",
        "Unit", "MutableList", "MutableMap",
      ],
      ["null", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["@"], capitalized_types: True)
}

pub fn php() -> Rules {
  let base =
    make(
      ["//", "#"],
      slash_block(),
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "abstract", "and", "array", "as", "break", "callable", "case", "catch",
        "class", "clone", "const", "continue", "declare", "default", "do",
        "echo", "else", "elseif", "empty", "enddeclare", "endfor",
        "endforeach", "endif", "endswitch", "endwhile", "enum", "extends",
        "final", "finally", "fn", "for", "foreach", "function", "global",
        "goto", "if", "implements", "include", "include_once", "instanceof",
        "insteadof", "interface", "isset", "list", "match", "namespace", "new",
        "or", "print", "private", "protected", "public", "readonly", "require",
        "require_once", "return", "static", "switch", "throw", "trait", "try",
        "unset", "use", "var", "while", "xor", "yield",
      ],
      [
        "bool", "float", "int", "iterable", "mixed", "never", "object",
        "string", "void", "self", "parent", "Closure", "Generator",
      ],
      ["null", "true", "false", "NULL", "TRUE", "FALSE"],
    )
  rules.Rules(
    ..base,
    identifier_start_extra: ["$"],
    identifier_extra: ["$"],
    heredocs: True,
  )
}

pub fn rust() -> Rules {
  let base =
    make(
      ["//"],
      nested_slash_block(),
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "as", "async", "await", "break", "const", "continue", "crate", "dyn",
        "else", "enum", "extern", "fn", "for", "if", "impl", "in", "let",
        "loop", "match", "mod", "move", "mut", "pub", "ref", "return", "self",
        "Self", "static", "struct", "super", "trait", "type", "unsafe", "use",
        "where", "while", "union", "macro_rules",
      ],
      [
        "bool", "char", "f32", "f64", "i8", "i16", "i32", "i64", "i128",
        "isize", "str", "u8", "u16", "u32", "u64", "u128", "usize", "String",
        "Vec", "Option", "Result", "Box", "HashMap", "HashSet", "Rc", "Arc",
        "RefCell",
      ],
      ["true", "false", "None", "Some", "Ok", "Err"],
    )
  rules.Rules(..base, meta_prefixes: ["#["], capitalized_types: True)
}

pub fn scala() -> Rules {
  let base =
    make(
      ["//"],
      nested_slash_block(),
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
        rules.quote("'", "'"),
      ],
      [
        "abstract", "case", "catch", "class", "def", "do", "else", "enum",
        "export", "extends", "extension", "final", "finally", "for", "given",
        "if", "implicit", "import", "lazy", "match", "new", "object",
        "override", "package", "private", "protected", "return", "sealed",
        "super", "then", "this", "throw", "trait", "try", "type", "using",
        "val", "var", "while", "with", "yield",
      ],
      [
        "Any", "AnyRef", "AnyVal", "Boolean", "Byte", "Char", "Double",
        "Float", "Int", "List", "Long", "Map", "Nothing", "Option", "Seq",
        "Set", "Short", "String", "Unit", "Vector", "Either", "Future",
      ],
      ["null", "true", "false", "None", "Some", "Nil"],
    )
  rules.Rules(..base, meta_prefixes: ["@"], capitalized_types: True)
}

pub fn swift() -> Rules {
  let base =
    make(
      ["//"],
      nested_slash_block(),
      [
        rules.raw_multiline_quote("\"\"\"", "\"\"\""),
        rules.quote("\"", "\""),
      ],
      [
        "actor", "any", "as", "associatedtype", "async", "await", "break",
        "case", "catch", "class", "continue", "convenience", "default",
        "defer", "deinit", "didSet", "do", "dynamic", "else", "enum",
        "extension", "fallthrough", "fileprivate", "final", "for", "func",
        "get", "guard", "if", "import", "in", "indirect", "infix", "init",
        "inout", "internal", "is", "lazy", "let", "mutating", "nonisolated",
        "nonmutating", "open", "operator", "override", "postfix",
        "precedencegroup", "prefix", "private", "protocol", "public", "repeat",
        "required", "rethrows", "return", "self", "set", "some", "static",
        "struct", "subscript", "super", "switch", "throw", "throws", "try",
        "typealias", "var", "weak", "where", "while", "willSet",
      ],
      [
        "Any", "AnyObject", "Array", "Bool", "Character", "Dictionary",
        "Double", "Error", "Float", "Int", "Int8", "Int16", "Int32", "Int64",
        "Optional", "Result", "Set", "String", "UInt", "Void",
      ],
      ["nil", "true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["@", "#"], capitalized_types: True)
}

pub fn zig() -> Rules {
  let base =
    make(
      ["//"],
      [],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "addrspace", "align", "allowzero", "and", "anyframe", "anytype", "asm",
        "async", "await", "break", "callconv", "catch", "comptime", "const",
        "continue", "defer", "else", "enum", "errdefer", "error", "export",
        "extern", "fn", "for", "if", "inline", "linksection", "noalias",
        "noinline", "nosuspend", "opaque", "or", "orelse", "packed", "pub",
        "resume", "return", "struct", "suspend", "switch", "test",
        "threadlocal", "try", "union", "unreachable", "usingnamespace", "var",
        "volatile", "while",
      ],
      [
        "anyerror", "anyopaque", "bool", "c_int", "c_long", "c_short",
        "comptime_float", "comptime_int", "f16", "f32", "f64", "f128", "i8",
        "i16", "i32", "i64", "i128", "isize", "noreturn", "type", "u8", "u16",
        "u32", "u64", "u128", "usize", "void",
      ],
      ["null", "true", "false", "undefined"],
    )
  rules.Rules(..base, meta_prefixes: ["@"])
}

/// Single Assignment C: C syntax with array-programming keywords.
pub fn sac() -> Rules {
  let base =
    make(
      ["//"],
      slash_block(),
      rules.common_quotes(),
      [
        "break", "case", "continue", "default", "do", "else", "external",
        "for", "goto", "if", "import", "inline", "module", "objdef", "provide",
        "return", "specialize", "step", "stop", "struct", "typedef", "use",
        "while", "with", "genarray", "modarray", "fold", "foldfix",
        "propagate", "class", "extern",
      ],
      [
        "bool", "byte", "char", "double", "float", "int", "long", "longlong",
        "short", "ubyte", "uint", "ulong", "ulonglong", "ushort", "void",
      ],
      ["true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["#"])
}

/// ATS mixes ML block comments with C-style line comments.
pub fn ats() -> Rules {
  let base =
    make(
      ["//"],
      [
        rules.BlockComment(open: "(*", close: "*)", nested: True),
        rules.BlockComment(open: "/*", close: "*/", nested: False),
      ],
      [rules.quote("\"", "\""), rules.quote("'", "'")],
      [
        "abstype", "abst0ype", "absprop", "absview", "absvtype",
        "absviewtype", "and", "assume", "begin", "break", "case", "castfn",
        "class", "datasort", "datatype", "dataprop", "dataview", "datavtype",
        "dataviewtype", "do", "dynload", "else", "end", "exception", "extern",
        "fn", "fnx", "for", "fun", "if", "implement", "in", "infix", "infixl",
        "infixr", "let", "local", "macdef", "match", "method", "nonfix", "of",
        "op", "overload", "prfn", "prfun", "prval", "praxi", "rec", "sif",
        "sortdef", "stadef", "staload", "symelim", "symintr", "then", "try",
        "typedef", "val", "var", "when", "where", "while", "with", "withtype",
      ],
      [
        "bool", "char", "double", "float", "int", "lint", "llint", "ptr",
        "size_t", "ssize_t", "string", "uint", "ulint", "void",
      ],
      ["true", "false"],
    )
  rules.Rules(..base, meta_prefixes: ["#"], identifier_extra: ["$"])
}
