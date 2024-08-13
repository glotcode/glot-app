use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
fun main(args : Array<String>){
    println("Hello World!")
}
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" space="preserve" viewBox="0 0 500 500" {
            linearGradient id="kotlinGradient" x1="500.003" x2="-.097" y1="579.106" y2="1079.206" gradientTransform="translate(.097 -578.99)scale(.9998)" gradientUnits="userSpaceOnUse" {
                stop offset=".003" style="stop-color:#e44857" {
                }
                stop offset=".469" style="stop-color:#c711e1" {
                }
                stop offset="1" style="stop-color:#7f52ff" {
                }
            }
            path d="M500 500H0V0h500L250 250z" style="fill:url(#kotlinGradient)" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Kotlin,
        name: "Kotlin".to_string(),
        logo_svg_path: "/static/assets/language/kotlin.svg?hash=checksum".to_string(),
        logo: logo(),
        file_extension: "kt".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.kt".to_string(),
            mode: "ace/mode/kotlin".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/kotlin:latest".to_string(),
            version_command: "kotlinc -version 2>&1 | cut -c 7-".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    let file_stem = main_file
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("Main");

    RunInstructions {
        build_commands: vec![format!("kotlinc {}", main_file.display())],
        run_command: format!("kotlin {}Kt", language::titlecase_ascii(file_stem)),
    }
}
