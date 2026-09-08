//// Lexer rules for the remaining languages: assembly, Cobol, and Pascal.

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

pub fn assembly() -> Rules {
  let base =
    make(
      [";", "#"],
      [rules.BlockComment(open: "/*", close: "*/", nested: False)],
      rules.common_quotes(),
      [
        "mov", "movq", "movl", "movb", "movw", "lea", "push", "pop", "add",
        "sub", "mul", "imul", "div", "idiv", "inc", "dec", "neg", "and", "or",
        "xor", "not", "shl", "shr", "sal", "sar", "cmp", "test", "jmp", "je",
        "jne", "jz", "jnz", "jg", "jge", "jl", "jle", "ja", "jae", "jb",
        "jbe", "call", "ret", "leave", "enter", "nop", "hlt", "int", "syscall",
        "loop", "cdq", "cqo", "setz", "setnz", "xchg",
      ],
      [
        "rax", "rbx", "rcx", "rdx", "rsi", "rdi", "rbp", "rsp", "r8", "r9",
        "r10", "r11", "r12", "r13", "r14", "r15", "eax", "ebx", "ecx", "edx",
        "esi", "edi", "ebp", "esp", "ax", "bx", "cx", "dx", "al", "bl", "cl",
        "dl", "byte", "word", "dword", "qword", "ptr",
      ],
      [],
    )
  rules.Rules(
    ..base,
    meta_prefixes: [".", "%"],
    identifier_extra: ["."],
    identifier_start_extra: ["%", "."],
    call_highlighting: False,
  )
}

pub fn cobol() -> Rules {
  let base =
    make(
      ["*>"],
      [],
      [
        rules.StringRule(
          open: "\"",
          close: "\"",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
        rules.StringRule(
          open: "'",
          close: "'",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
      ],
      [
        "IDENTIFICATION", "DIVISION", "PROGRAM-ID", "ENVIRONMENT",
        "CONFIGURATION", "SECTION", "INPUT-OUTPUT", "FILE-CONTROL", "DATA",
        "FILE", "WORKING-STORAGE", "LOCAL-STORAGE", "LINKAGE", "PROCEDURE",
        "ACCEPT", "ADD", "CALL", "CANCEL", "CLOSE", "COMPUTE", "CONTINUE",
        "DELETE", "DISPLAY", "DIVIDE", "ELSE", "END", "END-IF",
        "END-PERFORM", "END-EVALUATE", "EVALUATE", "EXIT", "GO", "GOBACK",
        "IF", "INITIALIZE", "INSPECT", "MERGE", "MOVE", "MULTIPLY", "OPEN",
        "PERFORM", "READ", "RELEASE", "RETURN", "REWRITE", "SEARCH", "SET",
        "SORT", "START", "STOP", "STRING", "SUBTRACT", "UNSTRING", "WHEN",
        "WRITE", "THEN", "UNTIL", "VARYING", "THROUGH", "THRU", "TO", "FROM",
        "GIVING", "BY", "USING", "SELECT", "ASSIGN", "ORGANIZATION",
      ],
      [
        "PIC", "PICTURE", "VALUE", "OCCURS", "REDEFINES", "USAGE", "COMP",
        "COMP-3", "BINARY", "DISPLAY", "PACKED-DECIMAL", "FILLER",
      ],
      ["ZERO", "ZEROS", "ZEROES", "SPACE", "SPACES", "HIGH-VALUE",
        "LOW-VALUE", "NULL", "TRUE", "FALSE"],
    )
  rules.Rules(
    ..base,
    identifier_extra: ["-"],
    fixed_format_comment_column: True,
    call_highlighting: False,
  )
}

pub fn pascal() -> Rules {
  let base =
    make(
      ["//"],
      [
        rules.BlockComment(open: "(*", close: "*)", nested: False),
        rules.BlockComment(open: "{", close: "}", nested: False),
      ],
      [
        rules.StringRule(
          open: "'",
          close: "'",
          escape: False,
          multiline: False,
          interpolation: False,
        ),
      ],
      [
        "and", "array", "asm", "begin", "case", "const", "constructor",
        "destructor", "div", "do", "downto", "else", "end", "file", "for",
        "function", "goto", "if", "implementation", "in", "inherited",
        "initialization", "inline", "interface", "label", "mod", "nil", "not",
        "object", "of", "operator", "or", "packed", "procedure", "program",
        "record", "repeat", "set", "shl", "shr", "then", "to", "type",
        "unit", "until", "uses", "var", "while", "with", "xor", "class",
        "private", "protected", "public", "published", "property", "try",
        "except", "finally", "raise",
      ],
      [
        "Boolean", "Byte", "Cardinal", "Char", "Comp", "Currency", "Double",
        "Extended", "Int64", "Integer", "LongInt", "LongWord", "Pointer",
        "Real", "ShortInt", "ShortString", "Single", "SmallInt", "String",
        "Text", "Word", "AnsiString", "WideString",
      ],
      ["nil", "true", "false", "True", "False"],
    )
  rules.Rules(..base, meta_prefixes: ["{$"], capitalized_types: True)
}
