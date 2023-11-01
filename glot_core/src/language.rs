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

use std::fmt;
use std::fmt::Display;
use std::path::PathBuf;

#[derive(Clone)]
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
        }
    }
}

#[derive(Clone)]
pub struct Config {
    id: Language,
    name: String,
    logo_name: String,
    file_extension: String,
    editor_config: EditorConfig,
    run_config: RunConfig,
}

#[derive(Clone)]
pub struct EditorConfig {
    default_filename: String,
    mode: String,
    use_soft_tabs: bool,
    soft_tab_size: u8,
    example_code: String,
}

#[derive(Clone)]
pub struct RunConfig {
    container_image: String,
    version_command: String,
}

#[derive(Clone)]
pub struct RunInstructions {
    pub build_commands: Vec<String>,
    pub run_command: String,
}

pub fn languages() -> Vec<Config> {
    vec![c::config(), assembly::config()]
}

pub fn run_instructions(
    id: &Language,
    main_file: PathBuf,
    other_files: Vec<PathBuf>,
) -> RunInstructions {
    match id {
        Language::C => c::run_instructions(main_file, other_files),
        Language::Assembly => assembly::run_instructions(main_file, other_files),
        Language::Ats => ats::run_instructions(main_file, other_files),
        Language::Bash => bash::run_instructions(main_file, other_files),
        Language::Clisp => clisp::run_instructions(main_file, other_files),
        Language::Clojure => clojure::run_instructions(main_file, other_files),
        Language::Cobol => cobol::run_instructions(main_file, other_files),
        Language::CoffeeScript => coffeescript::run_instructions(main_file, other_files),
        Language::Cpp => cpp::run_instructions(main_file, other_files),
        Language::Crystal => crystal::run_instructions(main_file, other_files),
        Language::Csharp => csharp::run_instructions(main_file, other_files),
        Language::D => d::run_instructions(main_file, other_files),
        Language::Dart => dart::run_instructions(main_file, other_files),
        Language::Elixir => elixir::run_instructions(main_file, other_files),
        Language::Elm => elm::run_instructions(main_file, other_files),
        Language::Erlang => erlang::run_instructions(main_file, other_files),
        Language::Fsharp => fsharp::run_instructions(main_file, other_files),
        Language::Go => go::run_instructions(main_file, other_files),
        Language::Groovy => groovy::run_instructions(main_file, other_files),
        Language::Guile => guile::run_instructions(main_file, other_files),
        Language::Hare => hare::run_instructions(main_file, other_files),
        Language::Haskell => haskell::run_instructions(main_file, other_files),
        Language::Idris => idris::run_instructions(main_file, other_files),
        Language::Java => java::run_instructions(main_file, other_files),
    }
}

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
