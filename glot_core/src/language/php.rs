use crate::language::EditorConfig;
use crate::language::LanguageConfig;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
<?php

echo "Hello World!\n";
"#;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Php;

impl LanguageConfig for Php {
    fn id(&self) -> String {
        "php".to_string()
    }

    fn name(&self) -> String {
        "PHP".to_string()
    }

    fn file_extension(&self) -> String {
        "php".to_string()
    }

    fn editor_config(&self) -> EditorConfig {
        EditorConfig {
            default_filename: format!("main.{}", self.file_extension()),
            mode: "ace/mode/php".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        }
    }

    fn run_config(&self) -> RunConfig {
        RunConfig {
            container_image: "glot/php:latest".to_string(),
            version_command: "php --version | head -n 1".to_string(),
        }
    }

    fn logo(&self) -> Markup {
        html! {
            svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 135" preserveAspectRatio="xMidYMid" {
                defs {
                    radialGradient id="a" cx=".837" cy="-125.811" r="363.057" gradientTransform="translate(76.464 81.918)scale(.463)" gradientUnits="userSpaceOnUse" {
                        stop offset="0" style="stop-color:#fff" {
                        }
                        stop offset=".5" style="stop-color:#4c6b97" {
                        }
                        stop offset="1" style="stop-color:#231f20" {
                        }
                    }
                }
                ellipse cx="128" cy="67.3" fill="url(#a)" rx="128" ry="67.3" {
                }
                ellipse cx="128" cy="67.3" fill="#6181B6" rx="123" ry="62.3" {
                }
                g fill="#FFF" {
                    path d="m152.9 87.5 6.1-31.4c1.4-7.1.2-12.4-3.4-15.7-3.5-3.2-9.5-4.8-18.3-4.8h-10.6l3-15.6c.1-.6 0-1.2-.4-1.7s-.9-.7-1.5-.7h-14.6c-1 0-1.8.7-2 1.6l-6.5 33.3c-.6-3.8-2-7-4.4-9.6-4.3-4.9-11-7.4-20.1-7.4H52.1c-1 0-1.8.7-2 1.6L37 104.7c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h14.7c1 0 1.8-.7 2-1.6l3.2-16.3h10.9c5.7 0 10.6-.6 14.3-1.8q5.85-1.95 10.5-6.3c2.5-2.3 4.6-4.9 6.2-7.7l-2.6 13.5c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h14.6c1 0 1.8-.7 2-1.6l7.2-37h10c4.3 0 5.5.8 5.9 1.2.3.3.9 1.5.2 5.2L134.1 87c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h15c.9-.3 1.7-1 1.9-1.9m-67.6-26c-.9 4.7-2.6 8.1-5.1 10s-6.6 2.9-12 2.9h-6.5l4.7-24.2h8.4c6.2 0 8.7 1.3 9.7 2.4 1.3 1.6 1.6 4.7.8 8.9M215.3 42.9c-4.3-4.9-11-7.4-20.1-7.4h-28.3c-1 0-1.8.7-2 1.6l-13.1 67.5c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h14.7c1 0 1.8-.7 2-1.6l3.2-16.3h10.9c5.7 0 10.6-.6 14.3-1.8q5.85-1.95 10.5-6.3c2.6-2.4 4.8-5.1 6.4-8s2.8-6.1 3.5-9.6c1.7-8.7.4-15.5-3.9-20.5M200 61.5c-.9 4.7-2.6 8.1-5.1 10s-6.6 2.9-12 2.9h-6.5l4.7-24.2h8.4c6.2 0 8.7 1.3 9.7 2.4 1.4 1.6 1.7 4.7.8 8.9" {
                    }
                }
                g fill="#000004" {
                    path d="M74.8 48.2c5.6 0 9.3 1 11.2 3.1s2.3 5.6 1.3 10.6c-1 5.2-3 9-5.9 11.2q-4.35 3.3-13.2 3.3h-8.9l5.5-28.2zM39 105h14.7l3.5-17.9h12.6c5.6 0 10.1-.6 13.7-1.8s6.8-3.1 9.8-5.9q3.75-3.45 6-7.5c1.5-2.7 2.6-5.7 3.2-9 1.6-8 .4-14.2-3.5-18.7s-10.1-6.7-18.6-6.7H52.1zM113.3 19.6h14.6l-3.5 17.9h13c8.2 0 13.8 1.4 16.9 4.3s4 7.5 2.8 13.9L151 87.1h-14.8l5.8-29.9c.7-3.4.4-5.7-.7-6.9s-3.6-1.9-7.3-1.9h-11.7l-7.5 38.7h-14.6zM189.5 48.2c5.6 0 9.3 1 11.2 3.1s2.3 5.6 1.3 10.6c-1 5.2-3 9-5.9 11.2q-4.35 3.3-13.2 3.3H174l5.5-28.2zM153.7 105h14.7l3.5-17.9h12.6c5.6 0 10.1-.6 13.7-1.8s6.8-3.1 9.8-5.9q3.75-3.45 6-7.5c1.5-2.7 2.6-5.7 3.2-9 1.6-8 .4-14.2-3.5-18.7s-10.1-6.7-18.6-6.7h-28.3z" {
                    }
                }
            }
        }
    }

    fn run_instructions(&self, main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
        RunInstructions {
            build_commands: vec![],
            run_command: format!("php {}", main_file.display()),
        }
    }
}
