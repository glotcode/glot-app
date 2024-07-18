use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
puts "Hello World!"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Crystal,
        name: "Crystal".to_string(),
        logo_svg_path: "/static/assets/language/crystal.svg?hash=checksum".to_string(),
        file_extension: "cr".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.cr".to_string(),
            mode: "ace/mode/crystal".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/crystal:latest".to_string(),
            version_command: "crystal --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("crystal run {}", main_file.display()),
    }
}
