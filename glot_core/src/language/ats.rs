use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use crate::util::file_util;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
implement main0 () = print"Hello World!\n"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Ats,
        name: "ATS".to_string(),
        logo_name: "ats".to_string(),
        file_extension: "dats".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.dats".to_string(),
            mode: "ace/mode/ats".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim().to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/ats:latest".to_string(),
            version_command: "patscc --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files =
        file_util::join_files(file_util::filter_by_extension(other_files, "dats"));

    RunInstructions {
        build_commands: vec![format!(
            "patscc -o a.out {} {}",
            main_file.display(),
            other_source_files
        )],
        run_command: "./a.out".to_string(),
    }
}
