use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
let
    hello = "Hello World!";
in
hello
"#;

pub fn config() -> Config {
    Config {
        id: Language::Nix,
        name: "Nix".to_string(),
        logo_name: "nix".to_string(),
        file_extension: "nix".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.nix".to_string(),
            mode: "ace/mode/nix".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/nix:latest".to_string(),
            version_command: "nix --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("nix-instantiate --eval {}", main_file.display()),
    }
}
