use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
say 'Hello World!';
"#;

pub fn config() -> Config {
    Config {
        id: Language::Raku,
        name: "Raku".to_string(),
        logo_svg_path: "/static/assets/language/raku.svg?hash=checksum".to_string(),
        file_extension: "raku".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.raku".to_string(),
            mode: "ace/mode/raku".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/raku:latest".to_string(),
            version_command: "raku --version | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("raku {}", main_file.display()),
    }
}
