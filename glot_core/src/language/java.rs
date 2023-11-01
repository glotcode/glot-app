use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
class Main {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Java,
        name: "Java".to_string(),
        logo_name: "java".to_string(),
        file_extension: "java".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.java".to_string(),
            mode: "ace/mode/java".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/java:latest".to_string(),
            version_command: "javac --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    let file_stem = main_file
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("Main");

    RunInstructions {
        build_commands: vec![format!("javac {}", main_file.display())],
        run_command: format!("java {}", language::titlecase_ascii(file_stem)),
    }
}
