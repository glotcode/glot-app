use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use crate::util::file_util;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
IO.puts "Hello World!"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Elixir,
        name: "Elixir".to_string(),
        logo_name: "elixir".to_string(),
        file_extension: "ex".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.ex".to_string(),
            mode: "ace/mode/elixir".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/elixir:latest".to_string(),
            version_command: "elixirc --version | tail -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = file_util::filter_by_extension(other_files, "c");

    RunInstructions {
        build_commands: vec![],
        run_command: format!(
            "elixirc {} {}",
            main_file.display(),
            file_util::join_files(other_source_files),
        ),
    }
}
