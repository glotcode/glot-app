use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
use fmt;

export fn main() void = {
    fmt::println("Hello World!")!;
};
"#;

pub fn config() -> Config {
    Config {
        id: Language::Guile,
        name: "Hare".to_string(),
        logo_name: "hare".to_string(),
        file_extension: "ha".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.ha".to_string(),
            mode: "ace/mode/plain_text".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/hare:latest".to_string(),
            version_command: "hare version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("hare build -o a.out {}", main_file.display())],
        run_command: "./a.out".to_string(),
    }
}
