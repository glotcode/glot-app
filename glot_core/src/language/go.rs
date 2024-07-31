use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
package main

import (
    "fmt"
)

func main() {
    fmt.Println("Hello World!")
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Go,
        name: "Go".to_string(),
        logo_svg_path: "/static/assets/language/go.svg?hash=checksum".to_string(),
        file_extension: "go".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.go".to_string(),
            mode: "ace/mode/golang".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/golang:latest".to_string(),
            version_command: "go version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("go build -o a.out {}", main_file.display())],
        run_command: "./a.out".to_string(),
    }
}
