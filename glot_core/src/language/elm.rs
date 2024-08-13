use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
module Main exposing (main)

import Html exposing (..)

main =
    text "Hello World!"
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" space="preserve" viewBox="0 0 323.141 322.95" {
            g fill="#34495E" {
                path d="m161.649 152.782 69.865-69.866H91.783zM8.867 0l70.374 70.375h152.972L161.838 0zM246.999 85.162l76.138 76.137-76.485 76.485-76.138-76.138zM323.298 143.724V0H179.573zM152.781 161.649 0 8.868v305.564zM255.522 246.655l67.776 67.777V178.879zM161.649 170.517 8.869 323.298H314.43z" {
                }
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Elm,
        name: "Elm".to_string(),
        logo: logo(),
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
