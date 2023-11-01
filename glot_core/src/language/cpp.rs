use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
#include <iostream>
using namespace std;

int main() {
    cout << "Hello World!";
    return 0;
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Cpp,
        name: "C++".to_string(),
        logo_name: "cpp".to_string(),
        file_extension: "cpp".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.cpp".to_string(),
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
    let other_source_files = language::filter_by_extension(other_files, "cpp");

    RunInstructions {
        build_commands: vec![format!(
            "clang++ -std=c++11 -o a.out {} {}",
            main_file.display(),
            language::join_files(other_source_files)
        )],
        run_command: "./a.out".to_string(),
    }
}
