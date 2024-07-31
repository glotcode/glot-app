use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
fn main() {
    println!("Hello World!");
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Rust,
        name: "Rust".to_string(),
        logo_svg_path: "/static/assets/language/rust.svg?hash=checksum".to_string(),
        file_extension: "rs".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.rs".to_string(),
            mode: "ace/mode/rust".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/rust:latest".to_string(),
            version_command: "rustc --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("rustc -o a.out {}", main_file.display())],
        run_command: "./a.out".to_string(),
    }
}
