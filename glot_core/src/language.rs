pub mod assembly;
pub mod ats;
pub mod bash;
pub mod c;
pub mod clisp;
pub mod clojure;
pub mod cobol;
pub mod coffeescript;
pub mod cpp;

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
    }
}
