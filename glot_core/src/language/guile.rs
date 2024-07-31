use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
(display "Hello World!")
"#;

pub fn config() -> Config {
    Config {
        id: Language::Guile,
        name: "Guile".to_string(),
        logo_svg_path: "/static/assets/language/guile.svg?hash=checksum".to_string(),
        file_extension: "scm".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.scm".to_string(),
            mode: "ace/mode/scheme".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/guile:latest".to_string(),
            version_command: "guile --version | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!(
            "guile --no-debug --fresh-auto-compile --no-auto-compile -s {}",
            main_file.display()
        ),
    }
}
