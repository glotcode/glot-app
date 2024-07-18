use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
:- module main.
:- interface.
:- import_module io.

:- pred main(io::di, io::uo) is det.

:- implementation.

main(!IO) :-
    io.write_string("Hello World!", !IO).
"#;

pub fn config() -> Config {
    Config {
        id: Language::Mercury,
        name: "Mercury".to_string(),
        logo_svg_path: "/static/assets/language/mercury.svg?hash=checksum".to_string(),
        file_extension: "m".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.m".to_string(),
            mode: "ace/mode/plain_text".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/mercury:latest".to_string(),
            version_command: "mmc --version | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = language::filter_by_extension(other_files, "m");

    RunInstructions {
        build_commands: vec![format!(
            "mmc -o a.out {} {}",
            main_file.display(),
            language::join_files(other_source_files)
        )],
        run_command: "./a.out".to_string(),
    }
}
