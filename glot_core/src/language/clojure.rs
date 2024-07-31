use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
(println "Hello World!")
"#;

pub fn config() -> Config {
    Config {
        id: Language::Clojure,
        name: "Clojure".to_string(),
        logo_svg_path: "/static/assets/language/clojure.svg?hash=checksum".to_string(),
        file_extension: "clj".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.clj".to_string(),
            mode: "ace/mode/clojure".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/clojure:latest".to_string(),
            version_command: "clj --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("clj -M {}", main_file.display()),
    }
}
