pub mod assembly;
pub mod ats;
pub mod bash;
pub mod c;
pub mod clisp;
pub mod clojure;
pub mod cobol;
pub mod coffeescript;
pub mod cpp;
pub mod crystal;
pub mod csharp;
pub mod d;
pub mod dart;
pub mod elixir;
pub mod elm;
pub mod erlang;
pub mod fsharp;
pub mod go;
pub mod groovy;
pub mod guile;
pub mod hare;
pub mod haskell;
pub mod idris;
pub mod java;
pub mod javascript;
pub mod julia;
pub mod kotlin;
pub mod lua;
pub mod mercury;
pub mod nim;
pub mod nix;
pub mod ocaml;
pub mod pascal;
pub mod perl;
pub mod php;
pub mod python;
pub mod raku;
pub mod ruby;
pub mod rust;
pub mod sac;
pub mod scala;
pub mod swift;
pub mod typescript;
pub mod zig;

use serde::Deserialize;
use serde::Serialize;
use std::fmt;
use std::fmt::Display;
use std::path::PathBuf;
use std::str::FromStr;

#[derive(Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum Language {
    Assembly,
    Ats,
    Bash,
    C,
    Clisp,
    Clojure,
    Cobol,
    CoffeeScript,
    Cpp,
    Crystal,
    Csharp,
    D,
    Dart,
    Elixir,
    Elm,
    Erlang,
    Fsharp,
    Go,
    Groovy,
    Guile,
    Hare,
    Haskell,
    Idris,
    Java,
    JavaScript,
    Julia,
    Kotlin,
    Lua,
    Mercury,
    Nim,
    Nix,
    Ocaml,
    Pascal,
    Perl,
    Php,
    Python,
    Raku,
    Ruby,
    Rust,
    Sac,
    Scala,
    Swift,
    TypeScript,
    Zig,
}

impl Language {
    pub fn list() -> Vec<Language> {
        vec![
            Language::Assembly,
            Language::Ats,
            Language::Bash,
            Language::C,
            Language::Clisp,
            Language::Clojure,
            Language::Cobol,
            Language::CoffeeScript,
            Language::Cpp,
            Language::Crystal,
            Language::Csharp,
            Language::D,
            Language::Dart,
            Language::Elixir,
            Language::Elm,
            Language::Erlang,
            Language::Fsharp,
            Language::Go,
            Language::Groovy,
            Language::Guile,
            Language::Hare,
            Language::Haskell,
            Language::Idris,
            Language::Java,
            Language::JavaScript,
            Language::Julia,
            Language::Kotlin,
            Language::Lua,
            Language::Mercury,
            Language::Nim,
            Language::Nix,
            Language::Ocaml,
            Language::Pascal,
            Language::Perl,
            Language::Php,
            Language::Python,
            Language::Raku,
            Language::Ruby,
            Language::Rust,
            Language::Sac,
            Language::Scala,
            Language::Swift,
            Language::TypeScript,
            Language::Zig,
        ]
    }

    pub fn config(&self) -> Config {
        match self {
            Self::Assembly => assembly::config(),
            Self::Ats => ats::config(),
            Self::Bash => bash::config(),
            Self::C => c::config(),
            Self::Clisp => clisp::config(),
            Self::Clojure => clojure::config(),
            Self::Cobol => cobol::config(),
            Self::CoffeeScript => coffeescript::config(),
            Self::Cpp => cpp::config(),
            Self::Crystal => crystal::config(),
            Self::Csharp => csharp::config(),
            Self::D => d::config(),
            Self::Dart => dart::config(),
            Self::Elixir => elixir::config(),
            Self::Elm => elm::config(),
            Self::Erlang => erlang::config(),
            Self::Fsharp => fsharp::config(),
            Self::Go => go::config(),
            Self::Groovy => groovy::config(),
            Self::Guile => guile::config(),
            Self::Hare => hare::config(),
            Self::Haskell => haskell::config(),
            Self::Idris => idris::config(),
            Self::Java => java::config(),
            Self::JavaScript => javascript::config(),
            Self::Julia => julia::config(),
            Self::Kotlin => kotlin::config(),
            Self::Lua => lua::config(),
            Self::Mercury => mercury::config(),
            Self::Nim => nim::config(),
            Self::Nix => nix::config(),
            Self::Ocaml => ocaml::config(),
            Self::Pascal => pascal::config(),
            Self::Perl => perl::config(),
            Self::Php => php::config(),
            Self::Python => python::config(),
            Self::Raku => raku::config(),
            Self::Ruby => ruby::config(),
            Self::Rust => rust::config(),
            Self::Sac => sac::config(),
            Self::Scala => scala::config(),
            Self::Swift => swift::config(),
            Self::TypeScript => typescript::config(),
            Self::Zig => zig::config(),
        }
    }

    pub fn run_instructions(
        &self,
        main_file: PathBuf,
        other_files: Vec<PathBuf>,
    ) -> RunInstructions {
        self.run_instructions_fn()(main_file, other_files)
    }

    fn run_instructions_fn(&self) -> RunInstructionsFn {
        match self {
            Self::Assembly => assembly::run_instructions,
            Self::Ats => ats::run_instructions,
            Self::Bash => bash::run_instructions,
            Self::C => c::run_instructions,
            Self::Clisp => clisp::run_instructions,
            Self::Clojure => clojure::run_instructions,
            Self::Cobol => cobol::run_instructions,
            Self::CoffeeScript => coffeescript::run_instructions,
            Self::Cpp => cpp::run_instructions,
            Self::Crystal => crystal::run_instructions,
            Self::Csharp => csharp::run_instructions,
            Self::D => d::run_instructions,
            Self::Dart => dart::run_instructions,
            Self::Elixir => elixir::run_instructions,
            Self::Elm => elm::run_instructions,
            Self::Erlang => erlang::run_instructions,
            Self::Fsharp => fsharp::run_instructions,
            Self::Go => go::run_instructions,
            Self::Groovy => groovy::run_instructions,
            Self::Guile => guile::run_instructions,
            Self::Hare => hare::run_instructions,
            Self::Haskell => haskell::run_instructions,
            Self::Idris => idris::run_instructions,
            Self::Java => java::run_instructions,
            Self::JavaScript => javascript::run_instructions,
            Self::Julia => julia::run_instructions,
            Self::Kotlin => kotlin::run_instructions,
            Self::Lua => lua::run_instructions,
            Self::Mercury => mercury::run_instructions,
            Self::Nim => nim::run_instructions,
            Self::Nix => nix::run_instructions,
            Self::Ocaml => ocaml::run_instructions,
            Self::Pascal => pascal::run_instructions,
            Self::Perl => perl::run_instructions,
            Self::Php => php::run_instructions,
            Self::Python => python::run_instructions,
            Self::Raku => raku::run_instructions,
            Self::Ruby => ruby::run_instructions,
            Self::Rust => rust::run_instructions,
            Self::Sac => sac::run_instructions,
            Self::Scala => scala::run_instructions,
            Self::Swift => swift::run_instructions,
            Self::TypeScript => typescript::run_instructions,
            Self::Zig => zig::run_instructions,
        }
    }
}

impl Display for Language {
    fn fmt(&self, f: &mut fmt::Formatter) -> Result<(), fmt::Error> {
        match self {
            Self::C => write!(f, "c"),
            Self::Assembly => write!(f, "assembly"),
            Self::Ats => write!(f, "ats"),
            Self::Bash => write!(f, "bash"),
            Self::Clisp => write!(f, "clisp"),
            Self::Clojure => write!(f, "clojure"),
            Self::Cobol => write!(f, "cobol"),
            Self::CoffeeScript => write!(f, "coffeescript"),
            Self::Cpp => write!(f, "cpp"),
            Self::Crystal => write!(f, "crystal"),
            Self::Csharp => write!(f, "csharp"),
            Self::D => write!(f, "d"),
            Self::Dart => write!(f, "dart"),
            Self::Elixir => write!(f, "elixir"),
            Self::Elm => write!(f, "elm"),
            Self::Erlang => write!(f, "erlang"),
            Self::Fsharp => write!(f, "fsharp"),
            Self::Go => write!(f, "go"),
            Self::Groovy => write!(f, "groovy"),
            Self::Guile => write!(f, "guile"),
            Self::Hare => write!(f, "hare"),
            Self::Haskell => write!(f, "haskell"),
            Self::Idris => write!(f, "idris"),
            Self::Java => write!(f, "java"),
            Self::JavaScript => write!(f, "javascript"),
            Self::Julia => write!(f, "julia"),
            Self::Kotlin => write!(f, "kotlin"),
            Self::Lua => write!(f, "lua"),
            Self::Mercury => write!(f, "mercury"),
            Self::Nim => write!(f, "nim"),
            Self::Nix => write!(f, "nix"),
            Self::Ocaml => write!(f, "ocaml"),
            Self::Pascal => write!(f, "pascal"),
            Self::Perl => write!(f, "perl"),
            Self::Php => write!(f, "php"),
            Self::Python => write!(f, "python"),
            Self::Raku => write!(f, "raku"),
            Self::Ruby => write!(f, "ruby"),
            Self::Rust => write!(f, "rust"),
            Self::Sac => write!(f, "sac"),
            Self::Scala => write!(f, "scala"),
            Self::Swift => write!(f, "swift"),
            Self::TypeScript => write!(f, "typescript"),
            Self::Zig => write!(f, "zig"),
        }
    }
}

#[derive(PartialEq, Eq, Debug)]
pub struct ParseIdError;

impl FromStr for Language {
    type Err = ParseIdError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Language::list()
            .into_iter()
            .filter(|language| s == language.config().id.to_string())
            .next()
            .ok_or(ParseIdError)
    }
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    pub id: Language,
    pub name: String,
    pub logo_svg_path: String,
    pub file_extension: String,
    pub editor_config: EditorConfig,
    pub run_config: RunConfig,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EditorConfig {
    pub default_filename: String,
    pub mode: String,
    pub use_soft_tabs: bool,
    pub soft_tab_size: u8,
    pub example_code: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunConfig {
    pub container_image: String,
    pub version_command: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunInstructions {
    pub build_commands: Vec<String>,
    pub run_command: String,
}

type RunInstructionsFn = fn(PathBuf, Vec<PathBuf>) -> RunInstructions;

/* HELPER FUNCTIONS */

pub fn filter_by_extension(files: Vec<PathBuf>, extension: &str) -> Vec<PathBuf> {
    files
        .into_iter()
        .filter(|file| file.extension().and_then(|s| s.to_str()) == Some(extension))
        .collect()
}

pub fn join_files(files: Vec<PathBuf>) -> String {
    files
        .iter()
        .map(|file| file.display().to_string())
        .collect::<Vec<String>>()
        .join(" ")
}

pub fn titlecase_ascii(s: &str) -> String {
    if !s.is_ascii() || s.len() < 2 {
        s.to_string()
    } else {
        let (head, tail) = s.split_at(1);
        format!("{}{}", head.to_ascii_uppercase(), tail)
    }
}
