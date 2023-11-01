use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
void main() {
    print('Hello World!');
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Dart,
        name: "Dart".to_string(),
        logo_name: "dart".to_string(),
        file_extension: "dart".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.dart".to_string(),
            mode: "ace/mode/dart".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/dart:latest".to_string(),
            version_command: "dart --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("dart {}", main_file.display()),
    }
}