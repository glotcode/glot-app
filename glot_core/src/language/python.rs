use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
print("Hello World!")
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 255" preserveAspectRatio="xMidYMid" {
            defs {
                linearGradient id="pythonGradient1" x1="12.959%" x2="79.639%" y1="12.039%" y2="78.201%" {
                    stop offset="0%" stop-color="#387EB8" {
                    }
                    stop offset="100%" stop-color="#366994" {
                    }
                }
                linearGradient id="pythonGradient2" x1="19.128%" x2="90.742%" y1="20.579%" y2="88.429%" {
                    stop offset="0%" stop-color="#FFE052" {
                    }
                    stop offset="100%" stop-color="#FFC331" {
                    }
                }
            }
            path fill="url(#pythonGradient1)" d="M126.916.072c-64.832 0-60.784 28.115-60.784 28.115l.072 29.128h61.868v8.745H41.631S.145 61.355.145 126.77c0 65.417 36.21 63.097 36.21 63.097h21.61v-30.356s-1.165-36.21 35.632-36.21h61.362s34.475.557 34.475-33.319V33.97S194.67.072 126.916.072M92.802 19.66a11.12 11.12 0 0 1 11.13 11.13 11.12 11.12 0 0 1-11.13 11.13 11.12 11.12 0 0 1-11.13-11.13 11.12 11.12 0 0 1 11.13-11.13" {
            }
            path fill="url(#pythonGradient2)" d="M128.757 254.126c64.832 0 60.784-28.115 60.784-28.115l-.072-29.127H127.6v-8.745h86.441s41.486 4.705 41.486-60.712c0-65.416-36.21-63.096-36.21-63.096h-21.61v30.355s1.165 36.21-35.632 36.21h-61.362s-34.475-.557-34.475 33.32v56.013s-5.235 33.897 62.518 33.897m34.114-19.586a11.12 11.12 0 0 1-11.13-11.13 11.12 11.12 0 0 1 11.13-11.131 11.12 11.12 0 0 1 11.13 11.13 11.12 11.12 0 0 1-11.13 11.13" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Python,
        name: "Python".to_string(),
        logo: logo(),
        file_extension: "py".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.py".to_string(),
            mode: "ace/mode/python".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/python:latest".to_string(),
            version_command: "python --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("python {}", main_file.display()),
    }
}
