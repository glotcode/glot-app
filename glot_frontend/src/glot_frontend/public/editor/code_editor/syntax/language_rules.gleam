//// Maps every supported language onto its own lexer rules.
////
//// The `case` is exhaustive over `language.Language`, so adding a language to
//// `glot_core` fails to compile until it has rules here. `Plaintext` is the one
//// deliberate blank: it, and stdin, render unhighlighted.

import gleam/option.{type Option}
import glot_core/language.{type Language}
import glot_frontend/public/editor/code_editor/syntax/rules.{type Rules}
import glot_frontend/public/editor/code_editor/syntax/rules_c_family
import glot_frontend/public/editor/code_editor/syntax/rules_functional
import glot_frontend/public/editor/code_editor/syntax/rules_other
import glot_frontend/public/editor/code_editor/syntax/rules_scripting

pub fn for_language(lang: Language) -> Rules {
  case lang {
    language.Plaintext -> rules.plain()
    language.Assembly -> rules_other.assembly()
    language.Ats -> rules_c_family.ats()
    language.Bash -> rules_scripting.bash()
    language.C -> rules_c_family.c()
    language.Clisp -> rules_functional.clisp()
    language.Clojure -> rules_functional.clojure()
    language.Cobol -> rules_other.cobol()
    language.CoffeeScript -> rules_scripting.coffeescript()
    language.Cpp -> rules_c_family.cpp()
    language.Crystal -> rules_scripting.crystal()
    language.Csharp -> rules_c_family.csharp()
    language.D -> rules_c_family.d()
    language.Dart -> rules_c_family.dart()
    language.Elixir -> rules_functional.elixir()
    language.Elm -> rules_functional.elm()
    language.Erlang -> rules_functional.erlang()
    language.Fsharp -> rules_functional.fsharp()
    language.Go -> rules_c_family.go()
    language.Groovy -> rules_c_family.groovy()
    language.Guile -> rules_functional.guile()
    language.Hare -> rules_c_family.hare()
    language.Haskell -> rules_functional.haskell()
    language.Idris -> rules_functional.idris()
    language.Java -> rules_c_family.java()
    language.JavaScript -> rules_c_family.javascript()
    language.Julia -> rules_functional.julia()
    language.Kotlin -> rules_c_family.kotlin()
    language.Lua -> rules_scripting.lua()
    language.Mercury -> rules_functional.mercury()
    language.Nim -> rules_scripting.nim()
    language.Nix -> rules_functional.nix()
    language.Ocaml -> rules_functional.ocaml()
    language.Pascal -> rules_other.pascal()
    language.Perl -> rules_scripting.perl()
    language.Php -> rules_c_family.php()
    language.Python -> rules_scripting.python()
    language.Raku -> rules_scripting.raku()
    language.Ruby -> rules_scripting.ruby()
    language.Rust -> rules_c_family.rust()
    language.Sac -> rules_c_family.sac()
    language.Scala -> rules_c_family.scala()
    language.Swift -> rules_c_family.swift()
    language.TypeScript -> rules_c_family.typescript()
    language.Zig -> rules_c_family.zig()
  }
}

/// The token the comment-toggling command inserts, if the language has one.
pub fn line_comment(lang: Language) -> Option(String) {
  case for_language(lang).line_comments {
    [first, ..] -> option.Some(first)
    [] -> option.None
  }
}

/// The block comment delimiters the block-comment command uses.
pub fn block_comment(lang: Language) -> Option(#(String, String)) {
  case for_language(lang).block_comments {
    [first, ..] -> option.Some(#(first.open, first.close))
    [] -> option.None
  }
}

/// Whether a language is highlighted at all. Only `Plaintext` answers `False`;
/// stdin is rendered with these same rules turned off by its own session.
pub fn is_highlighted(lang: Language) -> Bool {
  for_language(lang).highlights
}
