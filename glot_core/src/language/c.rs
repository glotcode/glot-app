use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use crate::util::file_util;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
#include <stdio.h>

int main(void) {
    printf("Hello World!\n");
    return 0;
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::C,
        name: "C".to_string(),
        logo_name: "c".to_string(),
        file_extension: "c".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.c".to_string(),
            mode: "ace/mode/c_cpp".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/clang:latest".to_string(),
            version_command: "clang --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = file_util::filter_by_extension(other_files, "c");

    RunInstructions {
        build_commands: vec![format!(
            "clang -o a.out -lm {} {}",
            main_file.display(),
            file_util::join_files(other_source_files),
        )],
        run_command: "./a.out".to_string(),
    }
}