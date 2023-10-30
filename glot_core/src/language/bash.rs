use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
echo Hello World!
"#;

pub fn config() -> Config {
    Config {
        id: Language::Bash,
        name: "Bash".to_string(),
        logo_name: "bash".to_string(),
        file_extension: "sh".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.sh".to_string(),
            mode: "ace/mode/sh".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim().to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/bash:latest".to_string(),
            version_command: "bash --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("bash {}", main_file.display()),
    }
}
