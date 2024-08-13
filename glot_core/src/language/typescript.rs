use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::Path;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
const greeting: string = "Hello World!"
console.log(greeting)
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" fill="#007ACC" version="1" viewBox="0 0 256 256" {
            rect width="100%" height="100%" fill="#fff" {
            }
            path d="M0 128v128h256V0H0zm157-4.5V135h-33v105H97V135H64v-23h93zm65-10.1c4.1.8 8.7 1.9 10.3 2.5l2.7 1.1v12.5c0 6.9-.2 12.5-.4 12.5s-2.3-1.1-4.7-2.4c-9-5.1-23.4-7-32.2-4.4-2.1.6-5.2 2.5-6.8 4.1-2.4 2.3-2.9 3.7-2.9 7.4 0 4 .5 5.1 3.8 8.2 2.1 2 9.9 6.6 17.5 10.4 16 7.9 24.1 14.6 27.8 22.9 3.3 7.4 3.4 23 .2 30-3 6.6-9.6 13.3-16.1 16.4-13.8 6.5-36.3 7.1-53.9 1.3l-6.3-2.1V206l5 3.6c6.5 4.7 14.9 7.6 23.7 8.2s15.3-1 19.3-4.8c2.5-2.3 3-3.6 3-7.4 0-7.3-4.2-11.1-21.4-19.5-15.2-7.5-20-10.9-24.5-17.5-10-14.5-7-36.7 6.4-46.8 11.4-8.7 30.3-11.9 49.5-8.4" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::TypeScript,
        name: "TypeScript".to_string(),
        logo_svg_path: "/static/assets/language/typescript.svg?hash=checksum".to_string(),
        logo: logo(),
        file_extension: "ts".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.ts".to_string(),
            mode: "ace/mode/typescript".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/typescript:latest".to_string(),
            version_command: "tsc --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("tsc {}", main_file.display())],
        run_command: format!("node {}", replace_extension(&main_file, "js").display()).to_string(),
    }
}

fn replace_extension(file: &Path, extension: &str) -> PathBuf {
    let mut new_file = file.to_path_buf();
    new_file.set_extension(extension);
    new_file
}
