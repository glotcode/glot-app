use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
Program Main;

begin
  writeln('Hello World!');
end.
"#;

pub fn config() -> Config {
    Config {
        id: Language::Pascal,
        name: "Pascal".to_string(),
        logo_svg_path: "/static/assets/language/pascal.svg?hash=checksum".to_string(),
        file_extension: "pp".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.pp".to_string(),
            mode: "ace/mode/pascal".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/pascal:latest".to_string(),
            version_command: "fpc -iW".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("fpc -oa.out {}", main_file.display())],
        run_command: "./a.out".to_string(),
    }
}
