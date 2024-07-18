use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
object Main extends App {
    println("Hello World!")
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Scala,
        name: "Scala".to_string(),
        logo_svg_path: "/static/assets/language/scala.svg?hash=checksum".to_string(),
        file_extension: "scala".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.scala".to_string(),
            mode: "ace/mode/scala".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/scala:latest".to_string(),
            version_command: "scalac --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("scalac {}", main_file.display())],
        run_command: "scala Main".to_string(),
    }
}
