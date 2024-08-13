use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
object Main extends App {
    println("Hello World!")
}
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" viewBox="-50 -70 352 572" preserveAspectRatio="xMidYMid" {
            defs {
                linearGradient id="scalaGradient1" x1="0%" x2="100%" y1="50%" y2="50%" {
                    stop offset="0%" stop-color="#4F4F4F" {
                    }
                    stop offset="100%" {
                    }
                }
                linearGradient id="scalaGradient2" x1="0%" x2="100%" y1="50%" y2="50%" {
                    stop offset="0%" stop-color="#C40000" {
                    }
                    stop offset="100%" stop-color="red" {
                    }
                }
            }
            path fill="url(#scalaGradient1)" d="M0 288v-32c0-5.394 116.377-14.428 192.2-32 36.628 8.49 63.8 18.969 63.8 32v32c0 13.024-27.172 23.51-63.8 32C116.376 302.425 0 293.39 0 288" transform="matrix(1 0 0 -1 0 544)" {
            }
            path fill="url(#scalaGradient1)" d="M0 160v-32c0-5.394 116.377-14.428 192.2-32 36.628 8.49 63.8 18.969 63.8 32v32c0 13.024-27.172 23.51-63.8 32C116.376 174.425 0 165.39 0 160" transform="matrix(1 0 0 -1 0 288)" {
            }
            path fill="url(#scalaGradient2)" d="M0 224v-96c0 8 256 24 256 64v96c0-40-256-56-256-64" transform="matrix(1 0 0 -1 0 416)" {
            }
            path fill="url(#scalaGradient2)" d="M0 96V0c0 8 256 24 256 64v96c0-40-256-56-256-64" transform="matrix(1 0 0 -1 0 160)" {
            }
            path fill="url(#scalaGradient2)" d="M0 352v-96c0 8 256 24 256 64v96c0-40-256-56-256-64" transform="matrix(1 0 0 -1 0 672)" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Scala,
        name: "Scala".to_string(),
        logo_svg_path: "/static/assets/language/scala.svg?hash=checksum".to_string(),
        logo: logo(),
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
