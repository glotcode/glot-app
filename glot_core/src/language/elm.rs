use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
module Main exposing (main)

import Html exposing (..)

main =
    text "Hello World!"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Elm,
        name: "Elm".to_string(),
        logo_svg_path: "/static/assets/language/elm.svg?hash=checksum".to_string(),
        file_extension: "elm".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.elm".to_string(),
            mode: "ace/mode/elm".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/elm:latest".to_string(),
            version_command: "elm --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("elm make --output a.js {}", main_file.display())],
        run_command: "elm-runner a.js".to_string(),
    }
}
