use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
main = putStrLn "Hello World!"
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 181" preserveAspectRatio="xMidYMid" {
            path fill="#F97E2F" d="m0 180.664 60.222-90.332L0 0h45.166l60.222 90.332-60.222 90.332z" {
            }
            path fill="#95653A" d="m60.222 180.664 60.222-90.332L60.222 0h45.166L225.83 180.664h-45.166l-37.637-56.457-37.639 56.457z" {
            }
            path fill="#F97E2F" d="m205.757 127.971-20.072-30.11 70.257-.002v30.112zM175.647 82.805l-20.074-30.11 100.369-.002v30.112z" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Haskell,
        name: "Haskell".to_string(),
        logo: logo(),
        file_extension: "hs".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.hs".to_string(),
            mode: "ace/mode/haskell".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/haskell:latest".to_string(),
            version_command: "ghc --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("runghc {}", main_file.display()),
    }
}
