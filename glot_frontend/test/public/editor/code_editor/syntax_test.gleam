//// Highlighting: exhaustive language coverage, plus representative fixtures
//// that go well beyond Hello World.

import gleam/list
import gleam/string
import glot_core/language
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/highlight_state
import glot_frontend/public/editor/code_editor/syntax/language_rules
import glot_frontend/public/editor/code_editor/syntax/scanner
import glot_frontend/public/editor/code_editor/syntax/token

pub fn cached_tokens_follow_language_and_multiline_state_changes_test() {
  let rules = language_rules.for_language(language.JavaScript)
  let source = document.from_string("/*\ncomment\n*/\nlet x = 1;")
  let #(_, cached) = highlight_state.lines(rules, highlight_state.new(), source, 0, 4)
  let changed = document.from_string("/*\n*/\n*/\nlet x = 1;")
  let #(actual, cached) = highlight_state.lines(rules, highlight_state.invalidate_from(cached, 1), changed, 0, 4)
  let #(expected, _) = highlight_state.lines(rules, highlight_state.new(), changed, 0, 4)
  assert actual == expected
  let plain = language_rules.for_language(language.Plaintext)
  let #(actual, _) = highlight_state.lines(plain, cached, changed, 0, 4)
  let #(expected, _) = highlight_state.lines(plain, highlight_state.new(), changed, 0, 4)
  assert actual == expected
}

pub fn cached_viewport_refresh_handles_line_insertions_test() {
  let rules = language_rules.for_language(language.JavaScript)
  let source = document.from_string("const first = 1;\nconst second = 2;")
  let #(before, cached) = highlight_state.lines(rules, highlight_state.new(), source, 0, 2)
  let #(again, cached) = highlight_state.lines(rules, cached, source, 0, 2)
  assert before == again
  let changed = document.from_string("// added\nconst first = 1;\nconst second = 2;")
  let #(actual, _) = highlight_state.lines(rules, highlight_state.invalidate_from(cached, 0), changed, 1, 3)
  let #(expected, _) = highlight_state.lines(rules, highlight_state.new(), changed, 1, 3)
  assert actual == expected
}

fn kinds(lang: language.Language, source: String) -> List(token.TokenKind) {
  let doc = document.from_string(source)
  let #(lines, _) =
    highlight_state.lines(
      language_rules.for_language(lang),
      highlight_state.new(),
      doc,
      0,
      document.line_count(doc),
    )
  lines
  |> list.flat_map(fn(line) { list.map(line.tokens, fn(item) { item.kind }) })
}

fn segments(
  lang: language.Language,
  source: String,
) -> List(#(token.TokenKind, String)) {
  let doc = document.from_string(source)
  let #(lines, _) =
    highlight_state.lines(
      language_rules.for_language(lang),
      highlight_state.new(),
      doc,
      0,
      document.line_count(doc),
    )
  lines
  |> list.flat_map(fn(line) { highlight_state.segments(line.text, line.tokens) })
}

fn has(
  lang: language.Language,
  source: String,
  kind: token.TokenKind,
  value: String,
) -> Bool {
  list.contains(segments(lang, source), #(kind, value))
}

// -- Coverage ----------------------------------------------------------------

pub fn every_supported_language_has_its_own_rules_test() {
  let missing =
    language.list()
    |> list.filter(fn(lang) { !language_rules.is_highlighted(lang) })

  assert missing == []
}

pub fn no_two_languages_silently_share_one_generic_lexer_test() {
  // Rules values differ per language; if a language were falling back to a
  // shared generic mode its keywords would be identical to another's.
  let keyword_sets =
    language.list()
    |> list.map(fn(lang) { language_rules.for_language(lang).keywords })
    |> list.filter(fn(keywords) { keywords != [] })

  assert list.length(keyword_sets) == list.length(language.list())
}

pub fn plaintext_is_deliberately_unhighlighted_test() {
  assert !language_rules.is_highlighted(language.Plaintext)
  assert list.all(kinds(language.Plaintext, "class if while \"x\" // y"), fn(
    kind,
  ) {
    kind == token.Plain
  })
}

pub fn every_language_tokenises_a_representative_program_test() {
  let untokenised =
    language.list()
    |> list.filter(fn(lang) {
      let source = fixture(lang)
      let found = kinds(lang, source)
      // Every language must produce at least one token that is not plain text.
      !list.any(found, fn(kind) { kind != token.Plain })
    })

  assert untokenised == []
}

pub fn every_language_survives_incomplete_input_test() {
  // Truncating a fixture at every line must never lose text or crash the
  // scanner: the tokens always cover the whole line.
  let broken =
    language.list()
    |> list.filter(fn(lang) {
      let source = fixture(lang)
      prefixes(string.split(source, "\n"))
      |> list.any(fn(prefix) { !covers_every_line(lang, prefix) })
    })

  assert broken == []
}

/// Every prefix of a program, so the scanner is exercised against code that is
/// still being typed.
fn prefixes(lines: List(String)) -> List(String) {
  list.index_map(lines, fn(_, index) {
    lines
    |> list.take(index + 1)
    |> string.join("\n")
  })
}

fn covers_every_line(lang: language.Language, source: String) -> Bool {
  let doc = document.from_string(source)
  let #(lines, _) =
    highlight_state.lines(
      language_rules.for_language(lang),
      highlight_state.new(),
      doc,
      0,
      document.line_count(doc),
    )
  list.all(lines, fn(line) {
    highlight_state.segments(line.text, line.tokens)
    |> list.map(fn(segment) { segment.1 })
    |> string.concat
    == line.text
  })
}

// -- Multiline constructs ----------------------------------------------------

pub fn block_comments_carry_state_across_lines_test() {
  let found = segments(language.C, "int a;\n/* start\nstill\nend */ int b;")

  assert list.contains(found, #(token.Comment, "/* start"))
  assert list.contains(found, #(token.Comment, "still"))
  assert list.contains(found, #(token.Comment, "end */"))
  assert list.contains(found, #(token.TypeName, "int"))
}

pub fn nested_block_comments_only_close_at_the_right_depth_test() {
  let found =
    segments(language.Rust, "/* outer /* inner */ still */ let x = 1;")

  assert list.contains(found, #(token.Comment, "/* outer /* inner */ still */"))
  assert list.contains(found, #(token.Keyword, "let"))
}

pub fn triple_quoted_strings_span_lines_test() {
  let found = segments(language.Python, "s = \"\"\"one\ntwo\"\"\"\nx = 1")

  assert list.contains(found, #(token.StringLiteral, "\"\"\"one"))
  assert list.contains(found, #(token.StringLiteral, "two\"\"\""))
  assert list.contains(found, #(token.NumberLiteral, "1"))
}

pub fn heredocs_run_until_their_terminator_test() {
  let found = segments(language.Bash, "cat <<EOF\nplain text\nEOF\necho done")

  assert list.contains(found, #(token.StringLiteral, "plain text"))
  assert list.contains(found, #(token.Meta, "EOF"))
}

pub fn an_unterminated_string_leaves_the_rest_editable_test() {
  let found = segments(language.JavaScript, "const a = \"open\nconst b = 1;")

  assert list.contains(found, #(token.Keyword, "const"))
  // The unterminated quote does not swallow the following line, because a plain
  // quoted string is not multiline.
  assert list.contains(found, #(token.NumberLiteral, "1"))
}

pub fn an_unterminated_block_comment_keeps_its_state_test() {
  let doc = document.from_string("/* open")
  let #(_, next) =
    scanner.scan_line(
      language_rules.for_language(language.C),
      scanner.Normal,
      document.line_text(doc, 0),
    )

  assert next == scanner.InBlockComment(0, 1)
}

// -- Per-language spot checks ------------------------------------------------

pub fn c_family_languages_highlight_their_own_vocabulary_test() {
  assert has(language.C, "#include <stdio.h>", token.Meta, "#include")
  assert has(language.Cpp, "template <class T>", token.Keyword, "template")
  assert has(language.Csharp, "public async Task Run()", token.Keyword, "async")
  assert has(language.D, "/+ nested +/ int x;", token.Comment, "/+ nested +/")
  assert has(language.Dart, "final list = <int>[];", token.Keyword, "final")
  assert has(language.Go, "func main() {}", token.Keyword, "func")
  assert has(language.Groovy, "def x = 1", token.Keyword, "def")
  assert has(language.Hare, "fn main() void = void;", token.Keyword, "fn")
  assert has(language.Java, "@Override public void run()", token.Meta, "@Override")
  assert has(language.JavaScript, "const $x = 1;", token.Keyword, "const")
  assert has(language.TypeScript, "type Alias = string;", token.Keyword, "type")
  assert has(language.Kotlin, "fun main() = Unit", token.Keyword, "fun")
  assert has(language.Php, "<?php $name = 'x';", token.Keyword, "namespace") == False
  assert has(language.Php, "function run($a) {}", token.Keyword, "function")
  assert has(language.Rust, "#[derive(Debug)] fn main() {}", token.Meta, "#[derive")
  assert has(language.Sac, "int main() { return 0; }", token.TypeName, "int")
  assert has(language.Scala, "case class Point(x: Int)", token.Keyword, "case")
  assert has(language.Swift, "@main struct App {}", token.Meta, "@main")
  assert has(language.Zig, "const std = @import(\"std\");", token.Meta, "@import")
  assert has(language.Ats, "fun main(): void = ()", token.Keyword, "fun")
}

pub fn functional_languages_highlight_their_own_vocabulary_test() {
  assert has(language.Clisp, "(defun add (a b) (+ a b))", token.Keyword, "defun")
  assert has(language.Clojure, "(defn add [a b] (+ a b))", token.Keyword, "defn")
  assert has(language.Guile, "(define (add a b) (+ a b))", token.Keyword, "define")
  assert has(language.Elixir, "defmodule App do", token.Keyword, "defmodule")
  assert has(language.Elm, "type alias Model = Int", token.Keyword, "type")
  assert has(language.Erlang, "-module(app).", token.Meta, "-module")
  assert has(language.Fsharp, "let rec loop x = loop x", token.Keyword, "let")
  assert has(language.Haskell, "data Tree a = Leaf", token.Keyword, "data")
  assert has(language.Idris, "total add : Nat -> Nat", token.Keyword, "total")
  assert has(language.Ocaml, "let rec map f = function", token.Keyword, "let")
  assert has(language.Mercury, ":- module app.", token.Keyword, "module")
  assert has(language.Nix, "{ pkgs }: with pkgs; 1", token.Keyword, "with")
  assert has(language.Julia, "function add(a, b)", token.Keyword, "function")
}

pub fn scripting_languages_highlight_their_own_vocabulary_test() {
  assert has(language.Bash, "if [ -f file ]; then", token.Keyword, "if")
  assert has(language.CoffeeScript, "add = (a, b) -> a + b", token.Keyword, "unless") == False
  assert has(language.CoffeeScript, "unless x then y", token.Keyword, "unless")
  assert has(language.Crystal, "def add(a, b)", token.Keyword, "def")
  assert has(language.Lua, "local function add(a, b)", token.Keyword, "local")
  assert has(language.Nim, "proc add(a, b: int): int =", token.Keyword, "proc")
  assert has(language.Perl, "sub add { my ($a) = @_; }", token.Keyword, "sub")
  assert has(language.Python, "def add(a, b):", token.Keyword, "def")
  assert has(language.Raku, "sub add($a, $b) { }", token.Keyword, "sub")
  assert has(language.Ruby, "def add(a, b)", token.Keyword, "def")
}

pub fn remaining_languages_highlight_their_own_vocabulary_test() {
  assert has(language.Assembly, "  mov rax, 1", token.Keyword, "mov")
  assert has(
    language.Cobol,
    "       IDENTIFICATION DIVISION.",
    token.Keyword,
    "IDENTIFICATION",
  )
  assert has(language.Pascal, "program Hello;", token.Keyword, "program")
}

pub fn cobol_comments_the_line_from_its_seventh_column_test() {
  let found = segments(language.Cobol, "      * this whole line is a comment")
  assert list.contains(found, #(token.Comment, "      * this whole line is a comment"))
}

// -- Fixtures ----------------------------------------------------------------

/// A short but non-trivial program for each language: a comment, a string, a
/// number, and a declaration, so the fixtures exercise more than Hello World.
fn fixture(lang: language.Language) -> String {
  case lang {
    language.Plaintext -> "just text\nmore text"
    language.Assembly ->
      "; entry point\nsection .text\nglobal _start\n_start:\n  mov rax, 60\n  syscall"
    language.Ats ->
      "(* greet *)\nimplement main0 () = let\n  val n = 42\nin print(\"hi\") end"
    language.Bash ->
      "#!/bin/bash\n# greet\nname=\"world\"\nfor i in 1 2 3; do\n  echo \"hello $name $i\"\ndone"
    language.C ->
      "#include <stdio.h>\n/* greet */\nint main(void) {\n  int n = 42;\n  printf(\"hello %d\\n\", n);\n  return 0;\n}"
    language.Clisp ->
      ";; greet\n(defun greet (name)\n  (format t \"hello ~a~%\" name))\n(greet \"world\")"
    language.Clojure ->
      ";; greet\n(defn greet [name]\n  (println (str \"hello \" name)))\n(greet \"world\")"
    language.Cobol ->
      "       IDENTIFICATION DIVISION.\n       PROGRAM-ID. HELLO.\n       PROCEDURE DIVISION.\n           DISPLAY \"hello\".\n           STOP RUN."
    language.CoffeeScript ->
      "# greet\ngreet = (name) ->\n  console.log \"hello #{name}\"\ngreet \"world\""
    language.Cpp ->
      "#include <iostream>\n/* greet */\nint main() {\n  std::string name = \"world\";\n  std::cout << name << 42 << std::endl;\n}"
    language.Crystal ->
      "# greet\ndef greet(name : String)\n  puts \"hello #{name}\"\nend\ngreet(\"world\")"
    language.Csharp ->
      "// greet\nclass Program {\n  static void Main() {\n    var name = \"world\";\n    System.Console.WriteLine(name + 42);\n  }\n}"
    language.D ->
      "/+ greet +/\nimport std.stdio;\nvoid main() {\n  int n = 42;\n  writeln(\"hello\", n);\n}"
    language.Dart ->
      "// greet\nvoid main() {\n  final name = 'world';\n  print('hello $name 42');\n}"
    language.Elixir ->
      "# greet\ndefmodule Greeter do\n  def greet(name) do\n    IO.puts(\"hello #{name}\")\n  end\nend"
    language.Elm ->
      "-- greet\nmodule Main exposing (main)\n\nmain : String\nmain =\n    \"hello\" ++ String.fromInt 42"
    language.Erlang ->
      "%% greet\n-module(greeter).\n-export([greet/1]).\n\ngreet(Name) ->\n    io:format(\"hello ~s~n\", [Name])."
    language.Fsharp ->
      "// greet\nlet greet name =\n    printfn \"hello %s\" name\n\ngreet \"world\""
    language.Go ->
      "// greet\npackage main\n\nimport \"fmt\"\n\nfunc main() {\n\tn := 42\n\tfmt.Println(\"hello\", n)\n}"
    language.Groovy ->
      "// greet\ndef greet(String name) {\n  println \"hello $name 42\"\n}\ngreet('world')"
    language.Guile ->
      ";; greet\n(define (greet name)\n  (display (string-append \"hello \" name)))\n(greet \"world\")"
    language.Hare ->
      "// greet\nuse fmt;\n\nexport fn main() void = {\n\tlet n: int = 42;\n\tfmt::printfln(\"hello {}\", n)!;\n};"
    language.Haskell ->
      "-- greet\nmodule Main where\n\nmain :: IO ()\nmain = putStrLn (\"hello \" ++ show 42)"
    language.Idris ->
      "-- greet\nmodule Main\n\nmain : IO ()\nmain = putStrLn \"hello\""
    language.Java ->
      "// greet\npublic class Main {\n  public static void main(String[] args) {\n    int n = 42;\n    System.out.println(\"hello \" + n);\n  }\n}"
    language.JavaScript ->
      "// greet\nconst greet = (name) => {\n  const n = 42;\n  console.log(`hello ${name} ${n}`);\n};\ngreet(\"world\");"
    language.Julia ->
      "# greet\nfunction greet(name::String)\n    println(\"hello $name 42\")\nend\ngreet(\"world\")"
    language.Kotlin ->
      "// greet\nfun main() {\n    val name = \"world\"\n    println(\"hello $name 42\")\n}"
    language.Lua ->
      "-- greet\nlocal function greet(name)\n  print(\"hello \" .. name .. 42)\nend\ngreet(\"world\")"
    language.Mercury ->
      "% greet\n:- module greeter.\n:- interface.\n:- import_module io.\n:- pred main(io::di, io::uo) is det."
    language.Nim ->
      "# greet\nproc greet(name: string) =\n  echo \"hello \", name, 42\n\ngreet(\"world\")"
    language.Nix ->
      "# greet\n{ pkgs ? import <nixpkgs> {} }:\nlet name = \"world\";\nin pkgs.writeText \"greeting\" \"hello ${name}\""
    language.Ocaml ->
      "(* greet *)\nlet greet name =\n  print_string (\"hello \" ^ name)\n\nlet () = greet \"world\""
    language.Pascal ->
      "{ greet }\nprogram Hello;\nvar n: Integer;\nbegin\n  n := 42;\n  WriteLn('hello ', n);\nend."
    language.Perl ->
      "# greet\nuse strict;\nmy $name = \"world\";\nsub greet { my ($n) = @_; print \"hello $n\\n\"; }\ngreet($name);"
    language.Php ->
      "<?php\n// greet\nfunction greet(string $name): void {\n    echo \"hello {$name} 42\";\n}\ngreet('world');"
    language.Python ->
      "# greet\ndef greet(name: str) -> None:\n    n = 42\n    print(f\"hello {name} {n}\")\n\ngreet(\"world\")"
    language.Raku ->
      "# greet\nsub greet(Str $name) {\n    say \"hello $name 42\";\n}\ngreet('world');"
    language.Ruby ->
      "# greet\ndef greet(name)\n  puts \"hello #{name} 42\"\nend\n\ngreet('world')"
    language.Rust ->
      "// greet\nfn main() {\n    let name = \"world\";\n    println!(\"hello {} {}\", name, 42);\n}"
    language.Sac ->
      "// greet\nint main() {\n  int n = 42;\n  return n;\n}"
    language.Scala ->
      "// greet\nobject Main {\n  def main(args: Array[String]): Unit = {\n    println(s\"hello 42\")\n  }\n}"
    language.Swift ->
      "// greet\nfunc greet(_ name: String) {\n    print(\"hello \\(name) 42\")\n}\ngreet(\"world\")"
    language.TypeScript ->
      "// greet\nfunction greet(name: string): void {\n  const n: number = 42;\n  console.log(`hello ${name} ${n}`);\n}\ngreet(\"world\");"
    language.Zig ->
      "// greet\nconst std = @import(\"std\");\n\npub fn main() !void {\n    const n: u8 = 42;\n    std.debug.print(\"hello {}\\n\", .{n});\n}"
  }
}

pub fn horizontal_viewport_bounds_spans_without_losing_unicode_text_test() {
  let source = string.repeat("🦊x=1;", 1000)
  let #(tokens, _) = scanner.scan_line(
    language_rules.for_language(language.JavaScript), scanner.Normal, source,
  )
  let visible = highlight_state.viewport_tokens(tokens, 600, 660)
  assert list.length(visible) <= 42
  let rendered = highlight_state.segments(source, visible)
  assert rendered |> list.map(fn(item) { item.1 }) |> string.join("") == source
  assert rendered |> list.filter(fn(item) { item.0 == token.NumberLiteral }) |> list.length == 10
}
