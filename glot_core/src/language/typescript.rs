use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::Path;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
const greeting: string = "Hello World!"
console.log(greeting)
"#;

pub fn config() -> Config {
    Config {
        id: Language::TypeScript,
        name: "TypeScript".to_string(),
        logo_svg_path: "/static/assets/language/typescript.svg?hash=checksum".to_string(),
        file_extension: "ts".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.ts".to_string(),
            mode: "ace/mode/typescript".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/typescript:latest".to_string(),
            version_command: "tsc --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("tsc {}", main_file.display())],
        run_command: format!("node {}", replace_extension(&main_file, "js").display()).to_string(),
    }
}

fn replace_extension(file: &Path, extension: &str) -> PathBuf {
    let mut new_file = file.to_path_buf();
    new_file.set_extension(extension);
    new_file
}
