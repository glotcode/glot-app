use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
console.log("Hello World!");
"#;

pub fn config() -> Config {
    Config {
        id: Language::JavaScript,
        name: "JavaScript".to_string(),
        logo_svg_path: "/static/assets/language/javascript.svg?hash=checksum".to_string(),
        file_extension: "js".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.js".to_string(),
            mode: "ace/mode/javascript".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/javascript:latest".to_string(),
            version_command: "node --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("node {}", main_file.display()),
    }
}
