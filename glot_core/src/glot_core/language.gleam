import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type Language {
  Plaintext
  Assembly
  Ats
  Bash
  C
  Clisp
  Clojure
  Cobol
  CoffeeScript
  Cpp
  Crystal
  Csharp
  D
  Dart
  Elixir
  Elm
  Erlang
  Fsharp
  Go
  Groovy
  Guile
  Hare
  Haskell
  Idris
  Java
  JavaScript
  Julia
  Kotlin
  Lua
  Mercury
  Nim
  Nix
  Ocaml
  Pascal
  Perl
  Php
  Python
  Raku
  Ruby
  Rust
  Sac
  Scala
  Swift
  TypeScript
  Zig
}

pub type RunInstructions {
  RunInstructions(build_commands: List(String), run_command: String)
}

pub fn list() -> List(Language) {
  [
    Assembly, Ats, Bash, C, Clisp, Clojure, Cobol, CoffeeScript, Cpp, Crystal,
    Csharp, D, Dart, Elixir, Elm, Erlang, Fsharp, Go, Groovy, Guile, Hare,
    Haskell, Idris, Java, JavaScript, Julia, Kotlin, Lua, Mercury, Nim, Nix,
    Ocaml, Pascal, Perl, Php, Python, Raku, Ruby, Rust, Sac, Scala, Swift,
    TypeScript, Zig,
  ]
}

pub fn name(lang: Language) -> String {
  case lang {
    Plaintext -> "Plaintext"
    Assembly -> "Assembly"
    Ats -> "Ats"
    Bash -> "Bash"
    C -> "C"
    Clisp -> "Clisp"
    Clojure -> "Clojure"
    Cobol -> "Cobol"
    CoffeeScript -> "CoffeeScript"
    Cpp -> "Cpp"
    Crystal -> "Crystal"
    Csharp -> "Csharp"
    D -> "D"
    Dart -> "Dart"
    Elixir -> "Elixir"
    Elm -> "Elm"
    Erlang -> "Erlang"
    Fsharp -> "Fsharp"
    Go -> "Go"
    Groovy -> "Groovy"
    Guile -> "Guile"
    Hare -> "Hare"
    Haskell -> "Haskell"
    Idris -> "Idris"
    Java -> "Java"
    JavaScript -> "JavaScript"
    Julia -> "Julia"
    Kotlin -> "Kotlin"
    Lua -> "Lua"
    Mercury -> "Mercury"
    Nim -> "Nim"
    Nix -> "Nix"
    Ocaml -> "Ocaml"
    Pascal -> "Pascal"
    Perl -> "Perl"
    Php -> "Php"
    Python -> "Python"
    Raku -> "Raku"
    Ruby -> "Ruby"
    Rust -> "Rust"
    Sac -> "Sac"
    Scala -> "Scala"
    Swift -> "Swift"
    TypeScript -> "TypeScript"
    Zig -> "Zig"
  }
}

pub fn to_string(lang: Language) -> String {
  case lang {
    Plaintext -> "plaintext"
    Assembly -> "assembly"
    Ats -> "ats"
    Bash -> "bash"
    C -> "c"
    Clisp -> "clisp"
    Clojure -> "clojure"
    Cobol -> "cobol"
    CoffeeScript -> "coffeescript"
    Cpp -> "cpp"
    Crystal -> "crystal"
    Csharp -> "csharp"
    D -> "d"
    Dart -> "dart"
    Elixir -> "elixir"
    Elm -> "elm"
    Erlang -> "erlang"
    Fsharp -> "fsharp"
    Go -> "go"
    Groovy -> "groovy"
    Guile -> "guile"
    Hare -> "hare"
    Haskell -> "haskell"
    Idris -> "idris"
    Java -> "java"
    JavaScript -> "javascript"
    Julia -> "julia"
    Kotlin -> "kotlin"
    Lua -> "lua"
    Mercury -> "mercury"
    Nim -> "nim"
    Nix -> "nix"
    Ocaml -> "ocaml"
    Pascal -> "pascal"
    Perl -> "perl"
    Php -> "php"
    Python -> "python"
    Raku -> "raku"
    Ruby -> "ruby"
    Rust -> "rust"
    Sac -> "sac"
    Scala -> "scala"
    Swift -> "swift"
    TypeScript -> "typescript"
    Zig -> "zig"
  }
}

pub fn from_string(s: String) -> Option(Language) {
  case s {
    "plaintext" -> Some(Plaintext)
    "assembly" -> Some(Assembly)
    "ats" -> Some(Ats)
    "bash" -> Some(Bash)
    "c" -> Some(C)
    "clisp" -> Some(Clisp)
    "clojure" -> Some(Clojure)
    "cobol" -> Some(Cobol)
    "coffeescript" -> Some(CoffeeScript)
    "cpp" -> Some(Cpp)
    "crystal" -> Some(Crystal)
    "csharp" -> Some(Csharp)
    "d" -> Some(D)
    "dart" -> Some(Dart)
    "elixir" -> Some(Elixir)
    "elm" -> Some(Elm)
    "erlang" -> Some(Erlang)
    "fsharp" -> Some(Fsharp)
    "go" -> Some(Go)
    "groovy" -> Some(Groovy)
    "guile" -> Some(Guile)
    "hare" -> Some(Hare)
    "haskell" -> Some(Haskell)
    "idris" -> Some(Idris)
    "java" -> Some(Java)
    "javascript" -> Some(JavaScript)
    "julia" -> Some(Julia)
    "kotlin" -> Some(Kotlin)
    "lua" -> Some(Lua)
    "mercury" -> Some(Mercury)
    "nim" -> Some(Nim)
    "nix" -> Some(Nix)
    "ocaml" -> Some(Ocaml)
    "pascal" -> Some(Pascal)
    "perl" -> Some(Perl)
    "php" -> Some(Php)
    "python" -> Some(Python)
    "raku" -> Some(Raku)
    "ruby" -> Some(Ruby)
    "rust" -> Some(Rust)
    "sac" -> Some(Sac)
    "scala" -> Some(Scala)
    "swift" -> Some(Swift)
    "typescript" -> Some(TypeScript)
    "zig" -> Some(Zig)
    _ -> None
  }
}

pub fn is_runnable(lang: Language) -> Bool {
  lang != Plaintext
}

pub fn is_writable(lang: Language) -> Bool {
  lang != Plaintext
}

pub fn from_writable_string(value: String) -> Option(Language) {
  case from_string(value) {
    Some(Plaintext) | None -> None
    Some(lang) -> Some(lang)
  }
}

pub fn from_container_image(image: String) -> Option(Language) {
  list.find(list(), fn(lang) { container_image(lang) == image })
  |> option.from_result
}

pub fn encode(lang: Language) -> json.Json {
  json.string(to_string(lang))
}

// This matches Elm's behavior: fail with "Invalid language: <s>"
pub fn decoder() -> decode.Decoder(Language) {
  use s <- decode.then(decode.string)
  case from_string(s) {
    Some(lang) -> decode.success(lang)
    None -> decode.failure(Assembly, "Invalid language: " <> s)
  }
}

pub fn file_extension(lang: Language) -> String {
  case lang {
    Plaintext -> "txt"
    Assembly -> "asm"
    Ats -> "dats"
    Bash -> "sh"
    C -> "c"
    Clisp -> "lsp"
    Clojure -> "clj"
    Cobol -> "cob"
    CoffeeScript -> "coffee"
    Cpp -> "cpp"
    Crystal -> "cr"
    Csharp -> "cs"
    D -> "d"
    Dart -> "dart"
    Elixir -> "ex"
    Elm -> "elm"
    Erlang -> "erl"
    Fsharp -> "fs"
    Go -> "go"
    Groovy -> "groovy"
    Guile -> "scm"
    Hare -> "ha"
    Haskell -> "hs"
    Idris -> "idr"
    Java -> "java"
    JavaScript -> "js"
    Julia -> "jl"
    Kotlin -> "kt"
    Lua -> "lua"
    Mercury -> "m"
    Nim -> "nim"
    Nix -> "nix"
    Ocaml -> "ml"
    Pascal -> "pas"
    Perl -> "pl"
    Php -> "php"
    Python -> "py"
    Raku -> "raku"
    Ruby -> "rb"
    Rust -> "rs"
    Sac -> "sac"
    Scala -> "scala"
    Swift -> "swift"
    TypeScript -> "ts"
    Zig -> "zig"
  }
}

pub fn container_image(lang: Language) -> String {
  case lang {
    Plaintext -> ""
    Assembly -> "glot/assembly:latest"
    Ats -> "glot/ats:latest"
    Bash -> "glot/bash:latest"
    C -> "glot/clang:latest"
    Clisp -> "glot/clisp:latest"
    Clojure -> "glot/clojure:latest"
    Cobol -> "glot/cobol:latest"
    CoffeeScript -> "glot/coffeescript:latest"
    Cpp -> "glot/clang:latest"
    Crystal -> "glot/crystal:latest"
    Csharp -> "glot/csharp:latest"
    D -> "glot/dlang:latest"
    Dart -> "glot/dart:latest"
    Elixir -> "glot/elixir:latest"
    Elm -> "glot/elm:latest"
    Erlang -> "glot/erlang:latest"
    Fsharp -> "glot/fsharp:latest"
    Go -> "glot/golang:latest"
    Groovy -> "glot/groovy:latest"
    Guile -> "glot/guile:latest"
    Hare -> "glot/hare:latest"
    Haskell -> "glot/haskell:latest"
    Idris -> "glot/idris:latest"
    Java -> "glot/java:latest"
    JavaScript -> "glot/javascript:latest"
    Julia -> "glot/julia:latest"
    Kotlin -> "glot/kotlin:latest"
    Lua -> "glot/lua:latest"
    Mercury -> "glot/mercury:latest"
    Nim -> "glot/nim:latest"
    Nix -> "glot/nix:latest"
    Ocaml -> "glot/ocaml:latest"
    Pascal -> "glot/pascal:latest"
    Perl -> "glot/perl:latest"
    Php -> "glot/php:latest"
    Python -> "glot/python:latest"
    Raku -> "glot/raku:latest"
    Ruby -> "glot/ruby:latest"
    Rust -> "glot/rust:latest"
    Sac -> "glot/sac:latest"
    Scala -> "glot/scala:latest"
    Swift -> "glot/swift:latest"
    TypeScript -> "glot/typescript:latest"
    Zig -> "glot/zig:latest"
  }
}

pub fn default_filename(lang: Language) -> String {
  case lang {
    Elm -> "Main." <> file_extension(lang)
    _ -> "main." <> file_extension(lang)
  }
}

fn version_command(lang: Language) -> String {
  case lang {
    Plaintext -> ""
    Assembly -> "nasm --version"
    Ats -> "patscc -vats"
    Bash -> "bash --version | head -n 1"
    C -> "clang --version | head -n 1"
    Clisp -> "sbcl --version"
    Clojure -> "clj --version"
    Cobol -> "cobc --version | head -n 1"
    CoffeeScript -> "coffee --version"
    Cpp -> "clang --version | head -n 1"
    Crystal -> "crystal --version | head -n 1"
    Csharp -> "mcs --version"
    D -> "dmd --version | head -n 1"
    Dart -> "dart --version"
    Elixir -> "elixirc --version | tail -n 1"
    Elm -> "elm --version"
    Erlang -> "erl -version 2>&1"
    Fsharp -> "fsharpc --version 2>/dev/null | head -n 1"
    Go -> "go version"
    Groovy -> "groovy --version"
    Guile -> "guile --version | head -n 1"
    Hare -> "hare version"
    Haskell -> "ghc --version"
    Idris -> "idris2 --version"
    Java -> "javac --version"
    JavaScript -> "node --version"
    Julia -> "julia --version"
    Kotlin -> "kotlinc -version 2>&1 | cut -c 7-"
    Lua -> "lua -v"
    Mercury -> "mmc --version | head -n 1"
    Nim -> "nim --version | head -n 1"
    Nix -> "nix --version"
    Ocaml -> "ocaml --version"
    Pascal -> "fpc -iV"
    Perl -> "perl --version | head -n 2 | tail -n 1"
    Php -> "php --version | head -n 1"
    Python -> "python --version"
    Raku -> "raku --version | head -n 1"
    Ruby -> "ruby --version"
    Rust -> "rustc --version"
    Sac -> "sac2c -V | head -n 1"
    Scala -> "scalac --version"
    Swift -> "swift --version | head -n 1"
    TypeScript -> "tsc --version"
    Zig -> "zig version"
  }
}

pub fn version_run_instructions(lang: Language) -> RunInstructions {
  RunInstructions(build_commands: [], run_command: version_command(lang))
}

pub fn encode_run_instructions(ri: RunInstructions) -> json.Json {
  json.object([
    #("buildCommands", json.array(ri.build_commands, json.string)),
    #("runCommand", json.string(ri.run_command)),
  ])
}

pub fn run_instructions_decoder() -> decode.Decoder(RunInstructions) {
  use build_commands <- decode.field(
    "buildCommands",
    decode.list(decode.string),
  )
  use run_command <- decode.field("runCommand", decode.string)

  decode.success(RunInstructions(
    build_commands: build_commands,
    run_command: run_command,
  ))
}

pub fn run_instructions(
  lang: Language,
  main_file: String,
  other_files: List(String),
) -> RunInstructions {
  case lang {
    Plaintext -> RunInstructions(build_commands: [], run_command: "")
    Assembly ->
      RunInstructions(
        build_commands: [
          "nasm -f elf64 -o a.o " <> main_file,
          "ld -o a.out a.o",
        ],
        run_command: "./a.out",
      )

    Ats ->
      RunInstructions(
        build_commands: [
          "patscc -o a.out "
          <> string.join(
            [main_file, ..filter_by_extension("dats", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    Bash ->
      RunInstructions(build_commands: [], run_command: "bash " <> main_file)

    C ->
      RunInstructions(
        build_commands: [
          "clang -o a.out -lm "
          <> string.join(
            [main_file, ..filter_by_extension("c", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    Clisp ->
      RunInstructions(
        build_commands: [],
        run_command: "sbcl --noinform --non-interactive --load " <> main_file,
      )

    Clojure ->
      RunInstructions(build_commands: [], run_command: "clj -M " <> main_file)

    Cobol ->
      RunInstructions(
        build_commands: [
          "cobc -x -o a.out "
          <> string.join(
            [main_file, ..filter_by_extension("cob", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    CoffeeScript ->
      RunInstructions(build_commands: [], run_command: "coffee " <> main_file)

    Cpp ->
      RunInstructions(
        build_commands: [
          "clang++ -std=c++11 -o a.out "
          <> string.join(
            [main_file, ..filter_by_extension("cpp", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    Crystal ->
      RunInstructions(
        build_commands: [],
        run_command: "crystal run " <> main_file,
      )

    Csharp ->
      RunInstructions(
        build_commands: [
          "mcs -out:a.exe "
          <> string.join(
            [main_file, ..filter_by_extension("cs", other_files)],
            with: " ",
          ),
        ],
        run_command: "mono a.exe",
      )

    D ->
      RunInstructions(
        build_commands: [
          "dmd -ofa.out "
          <> string.join(
            [main_file, ..filter_by_extension("d", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    Dart ->
      RunInstructions(build_commands: [], run_command: "dart " <> main_file)

    Elixir ->
      RunInstructions(
        build_commands: [],
        run_command: "elixirc "
          <> string.join(
          [main_file, ..filter_by_extension("c", other_files)],
          with: " ",
        ),
      )

    Elm ->
      RunInstructions(
        build_commands: ["elm make --output a.js " <> main_file],
        run_command: "elm-runner a.js",
      )

    Erlang -> {
      let build =
        list.map(filter_by_extension("erl", other_files), fn(f) { "erlc " <> f })

      RunInstructions(
        build_commands: build,
        run_command: "escript " <> main_file,
      )
    }

    Fsharp -> {
      let others = list.reverse(filter_by_extension("fs", other_files))
      let files = list.append(others, [main_file])

      RunInstructions(
        build_commands: [
          "fsharpc --out:a.exe " <> string.join(files, with: " "),
        ],
        run_command: "mono a.exe",
      )
    }

    Go ->
      RunInstructions(
        build_commands: ["go build -o a.out " <> main_file],
        run_command: "./a.out",
      )

    Groovy ->
      RunInstructions(build_commands: [], run_command: "groovy " <> main_file)

    Guile ->
      RunInstructions(
        build_commands: [],
        run_command: "guile --no-debug --fresh-auto-compile --no-auto-compile -s "
          <> main_file,
      )

    Hare ->
      RunInstructions(
        build_commands: ["hare build -o a.out " <> main_file],
        run_command: "./a.out",
      )

    Haskell ->
      RunInstructions(build_commands: [], run_command: "runghc " <> main_file)

    Idris ->
      RunInstructions(
        build_commands: ["idris2 -o a.out --output-dir . " <> main_file],
        run_command: "./a.out",
      )

    Java -> {
      let main_class = titlecase_ascii(file_stem(main_file))

      RunInstructions(
        build_commands: ["javac " <> main_file],
        run_command: "java " <> main_class,
      )
    }

    JavaScript ->
      RunInstructions(build_commands: [], run_command: "node " <> main_file)

    Julia ->
      RunInstructions(build_commands: [], run_command: "julia " <> main_file)

    Kotlin -> {
      let class_base = titlecase_ascii(file_stem(main_file))

      RunInstructions(
        build_commands: ["kotlinc " <> main_file],
        run_command: "kotlin " <> class_base <> "Kt",
      )
    }

    Lua -> RunInstructions(build_commands: [], run_command: "lua " <> main_file)

    Mercury ->
      RunInstructions(
        build_commands: [
          "mmc -o a.out "
          <> string.join(
            [main_file, ..filter_by_extension("m", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    Nim ->
      RunInstructions(
        build_commands: [],
        run_command: "nim --hints:off --verbosity:0 compile --run " <> main_file,
      )

    Nix ->
      RunInstructions(
        build_commands: [],
        run_command: "nix-instantiate --eval " <> main_file,
      )

    Ocaml -> {
      let others = list.reverse(filter_by_extension("ml", other_files))
      let files = list.append(others, [main_file])

      RunInstructions(
        build_commands: [
          "ocamlc -o a.out " <> string.join(files, with: " "),
        ],
        run_command: "./a.out",
      )
    }

    Pascal ->
      RunInstructions(
        build_commands: [
          "fpc -oa.out "
          <> string.join(
            [main_file, ..filter_by_extension("pas", other_files)],
            with: " ",
          ),
        ],
        run_command: "./a.out",
      )

    Perl ->
      RunInstructions(build_commands: [], run_command: "perl " <> main_file)

    Php -> RunInstructions(build_commands: [], run_command: "php " <> main_file)

    Python ->
      RunInstructions(build_commands: [], run_command: "python " <> main_file)

    Raku ->
      RunInstructions(build_commands: [], run_command: "raku " <> main_file)

    Ruby ->
      RunInstructions(build_commands: [], run_command: "ruby " <> main_file)

    Rust ->
      RunInstructions(
        build_commands: ["rustc -o a.out " <> main_file],
        run_command: "./a.out",
      )

    Sac ->
      RunInstructions(
        build_commands: ["sac2c -t seq -o a.out " <> main_file],
        run_command: "./a.out",
      )

    Scala ->
      RunInstructions(
        build_commands: ["scalac " <> main_file],
        run_command: "scala Main",
      )

    Swift ->
      RunInstructions(build_commands: [], run_command: "swift " <> main_file)

    TypeScript ->
      RunInstructions(
        build_commands: ["tsc " <> main_file],
        run_command: "node " <> replace_extension("js", main_file),
      )

    Zig ->
      RunInstructions(build_commands: [], run_command: "zig run " <> main_file)
  }
}

fn filter_by_extension(ext: String, files: List(String)) -> List(String) {
  list.filter(files, fn(p) { get_extension(p) == Some(ext) })
}

fn get_extension(path: String) -> Option(String) {
  let file = tuple_second(dir_and_file(path))
  let parts = string.split(file, ".")
  case list.reverse(parts) {
    [] -> None
    [_] -> None
    [ext, ..] -> Some(ext)
  }
}

fn file_stem(path: String) -> String {
  let file = tuple_second(dir_and_file(path))
  let parts = string.split(file, ".")
  case list.reverse(parts) {
    [] -> ""
    [name_only] -> name_only
    [_ext, ..rev_rest] -> string.join(list.reverse(rev_rest), with: ".")
  }
}

fn dir_and_file(path: String) -> #(String, String) {
  let parts = string.split(path, "/")
  case list.reverse(parts) {
    [] -> #("", "")
    [file, ..rev_dirs] -> #(
      string.join(list.reverse(rev_dirs), with: "/"),
      file,
    )
  }
}

fn replace_extension(new_ext: String, path: String) -> String {
  let #(dir, file) = dir_and_file(path)

  let base = case list.reverse(string.split(file, ".")) {
    [] -> file
    [only] -> only
    [_old, ..rev_rest] -> string.join(list.reverse(rev_rest), with: ".")
  }

  let new_name = base <> "." <> new_ext

  case dir {
    "" -> new_name
    _ -> dir <> "/" <> new_name
  }
}

// Minimal helpers for tuple access (since Gleam tuples are positional)
fn tuple_second(t: #(a, b)) -> b {
  let #(_a, b) = t
  b
}

fn titlecase_ascii(s: String) -> String {
  // Elm did: upper first char, lower the rest (ASCII-ish)
  // Gleam doesn't have Char-based string uncons in the same way, so do it by slicing.
  case string.length(s) {
    0 -> s
    _ -> {
      let first = string.slice(s, 0, 1)
      let rest = string.slice(s, 1, string.length(s))
      string.uppercase(first) <> string.lowercase(rest)
    }
  }
}

fn trim_final_newline(s: String) -> String {
  case string.slice(s, -1, 1) {
    "\n" -> string.slice(s, 0, string.length(s) - 1)
    _ -> s
  }
}

pub fn example_code(lang: Language) -> String {
  trim_final_newline(case lang {
    Plaintext -> ""
    Assembly ->
      "section .data
    msg db \"Hello World!\", 0ah

section .text
    global _start
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 13
    syscall
    mov rax, 60
    mov rdi, 0
    syscall
"

    Ats ->
      "implement main0 () = print\"Hello World!\"
"

    Bash ->
      "echo Hello World!
"

    C ->
      "#include <stdio.h>

int main(void) {
    printf(\"Hello World!\");
    return 0;
}
"

    Clisp ->
      "(format t \"Hello World!\")
"

    Clojure ->
      "(println \"Hello World!\")
"

    Cobol ->
      "       IDENTIFICATION DIVISION.
       PROGRAM-ID. hello.

       PROCEDURE DIVISION.
           DISPLAY 'Hello World!'
           GOBACK
           .
"

    CoffeeScript ->
      "console.log \"Hello World!\"
"

    Cpp ->
      "#include <iostream>
using namespace std;

int main() {
    cout << \"Hello World!\";
    return 0;
}
"

    Crystal ->
      "puts \"Hello World!\"
"

    Csharp ->
      "using System;
using System.Collections.Generic;
using System.Linq;

class MainClass {
    static void Main() {
        Console.WriteLine(\"Hello World!\");
    }
}
"

    D ->
      "import std.stdio;

void main()
{
    writeln(\"Hello World!\");
}
"

    Dart ->
      "void main() {
    print('Hello World!');
}
"

    Elixir ->
      "IO.puts \"Hello World!\"
"

    Elm ->
      "module Main exposing (main)

import Html exposing (..)

main =
    text \"Hello World!\"
"

    Erlang ->
      "% escript will ignore the first line

main(_) ->
    io:format(\"Hello World!~n\").
"

    Fsharp ->
      "printfn \"Hello World!\"
"

    Go ->
      "package main

import (
    \"fmt\"
)

func main() {
    fmt.Println(\"Hello World!\")
}
"

    Groovy ->
      "println \"Hello World!\"
"

    Guile ->
      "(display \"Hello World!\")
"

    Hare ->
      "use fmt;

export fn main() void = {
    fmt::println(\"Hello World!\")!;
};
"

    Haskell ->
      "main = putStrLn \"Hello World!\"
"

    Idris ->
      "module Main

main : IO ()
main = putStrLn \"Hello World!\"
"

    Java ->
      "class Main {
    public static void main(String[] args) {
        System.out.println(\"Hello World!\");
    }
}
"

    JavaScript ->
      "console.log(\"Hello World!\");
"

    Julia ->
      "println(\"Hello world!\")
"

    Kotlin ->
      "fun main(args : Array<String>) {
    println(\"Hello World!\")
}
"

    Lua ->
      "print(\"Hello World!\");
"

    Mercury ->
      ":- module main.
:- interface.
:- import_module io.

:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string(\"Hello World!\", !IO).
"

    Nim ->
      "echo(\"Hello World!\")
"

    Nix ->
      "let
    hello = \"Hello World!\";
in
hello
"

    Ocaml ->
      "print_endline \"Hello World!\"
"

    Pascal ->
      "Program Main;

begin
  writeln('Hello World!');
end.
"

    Perl -> "print \"Hello World!\";"

    Php ->
      "<?php

echo \"Hello World!\";"

    Python ->
      "print(\"Hello World!\")
"

    Raku ->
      "say 'Hello World!';
"

    Ruby ->
      "puts \"Hello World!\"
"

    Rust ->
      "fn main() {
    println!(\"Hello World!\");
}
"

    Sac ->
      "int main () {
    StdIO::printf (\"Hello World!\");
    return 0;
}
"

    Scala ->
      "object Main extends App {
    println(\"Hello World!\")
}
"

    Swift ->
      "print(\"Hello World!\")
"

    TypeScript ->
      "const greeting: string = \"Hello World!\"
console.log(greeting)
"

    Zig ->
      "const std = @import(\"std\");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(\"{s}\", .{\"Hello World!\"});
}
"
  })
}
