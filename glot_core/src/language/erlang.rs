use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
% escript will ignore the first line

main(_) ->
    io:format("Hello World!~n").
"#;

pub fn config() -> Config {
    Config {
        id: Language::Erlang,
        name: "Erlang".to_string(),
        logo_name: "erlang".to_string(),
        file_extension: "erl".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.erl".to_string(),
            mode: "ace/mode/erlang".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/erlang:latest".to_string(),
            version_command: "erl -version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let build_commands = language::filter_by_extension(other_files, "erl")
        .iter()
        .map(|file| format!("erlc {}", file.to_string_lossy()))
        .collect();

    RunInstructions {
        build_commands,
        run_command: format!("escript {}", main_file.display()),
    }
}
