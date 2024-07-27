use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
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
        logo_svg_path: "/static/assets/language/generic.svg?hash=checksum".to_string(),
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
            version_command: "cobc --version | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = language::filter_by_extension(other_files, "cob");

    RunInstructions {
        build_commands: vec![format!(
            "cobc -x -o a.out {} {}",
            main_file.display(),
            language::join_files(other_source_files)
        )],
        run_command: "./a.out".to_string(),
    }
}
