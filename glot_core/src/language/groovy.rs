use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
println "Hello World!"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Groovy,
        name: "Groovy".to_string(),
        logo_name: "groovy".to_string(),
        file_extension: "groovy".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.groovy".to_string(),
            mode: "ace/mode/groovy".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/groovy:latest".to_string(),
            version_command: "groovy --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("groovy {}", main_file.display()),
    }
}