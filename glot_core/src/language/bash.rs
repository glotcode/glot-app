use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
echo Hello World!
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" space="preserve" viewBox="0 0 512 512" {
            path d="m77.554 296.055 101.189-39.863v-.611L77.554 215.413v-44.464l154.539 68.379v32.807L77.554 340.514zm356.892 47.832v39.863H251.7v-39.863zM468.917.5H43.083C19.662.5.5 19.663.5 43.083v425.833c0 23.421 19.162 42.583 42.583 42.583h425.834c23.421 0 42.583-19.162 42.583-42.583V43.083C511.5 19.663 492.338.5 468.917.5m0 468.417H43.083V106.958h425.834z" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Bash,
        name: "Bash".to_string(),
        logo_svg_path: "/static/assets/language/bash.svg?hash=checksum".to_string(),
        logo: logo(),
        file_extension: "sh".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.sh".to_string(),
            mode: "ace/mode/sh".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/bash:latest".to_string(),
            version_command: "bash --version | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("bash {}", main_file.display()),
    }
}
