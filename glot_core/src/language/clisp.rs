use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
(format t "Hello World!")
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" {
            circle cx="256" cy="256" r="235" fill="#fff" {
            }
            path stroke="#000" stroke-width="5" d="M255.6 20a236 236 0 1 0 .8 472 236 236 0 0 0-.8-472zm2.2 1A235 235 0 0 1 422 422.3 117.5 117.5 0 0 1 256 256 119.4 119.4 0 0 0 115.5 66.4 234.2 234.2 0 0 1 257.8 21zM67 151.3h40c10 42.1 25.2 79.4 40.8 116.4A677.5 677.5 0 0 1 203 151.3h40c-49 97.3-102.2 164-24 250h-40c-47.6-77.3-82.4-147.7-112-250z" {
            }
            path d="M293 110.7c78.2 86 25 152.7-24 250h40c22-35.2 39.4-75 55.3-116.4 15.5 37 30.8 74.3 40.7 116.4h40c-29.6-102.3-64.4-172.7-112-250z" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Clisp,
        name: "Common Lisp".to_string(),
        logo_svg_path: "/static/assets/language/clisp.svg?hash=checksum".to_string(),
        logo: logo(),
        file_extension: "lsp".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.lsp".to_string(),
            mode: "ace/mode/lisp".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/clisp:latest".to_string(),
            version_command: "sbcl --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!(
            "sbcl --noinform --non-interactive --load {}",
            main_file.display()
        ),
    }
}
