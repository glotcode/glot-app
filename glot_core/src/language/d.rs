use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
import std.stdio;

void main()
{
    writeln("Hello World!");
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::D,
        name: "D".to_string(),
        logo_name: "d".to_string(),
        file_extension: "d".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.d".to_string(),
            mode: "ace/mode/d".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/dlang:latest".to_string(),
            version_command: "dmd --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = language::filter_by_extension(other_files, "d");

    RunInstructions {
        build_commands: vec![format!(
            "dmd -ofa.out {} {}",
            main_file.display(),
            language::join_files(other_source_files)
        )],
        run_command: "./a.out".to_string(),
    }
}
