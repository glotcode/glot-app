use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use crate::util::file_util;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
       IDENTIFICATION DIVISION.
       PROGRAM-ID. hello.

       PROCEDURE DIVISION.
           DISPLAY 'Hello World!'
           GOBACK
           .
"#;

pub fn config() -> Config {
    Config {
        id: Language::Cobol,
        name: "Cobol".to_string(),
        logo_name: "cobol".to_string(),
        file_extension: "cob".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.cob".to_string(),
            mode: "ace/mode/cobol".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/cobol:latest".to_string(),
            version_command: "cobc --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = file_util::filter_by_extension(other_files, "cob");

    RunInstructions {
        build_commands: vec![format!(
            "cobc -x -o a.out {} {}",
            main_file.display(),
            file_util::join_files(other_source_files)
        )],
        run_command: "./a.out".to_string(),
    }
}