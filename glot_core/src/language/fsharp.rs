use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
printfn "Hello World!"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Fsharp,
        name: "F#".to_string(),
        logo_svg_path: "/static/assets/language/fsharp.svg?hash=checksum".to_string(),
        file_extension: "fs".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.fs".to_string(),
            mode: "ace/mode/fsharp".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/fsharp:latest".to_string(),
            version_command: "fsharpc --version 2>/dev/null | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = language::filter_by_extension(other_files, "fs")
        .into_iter()
        .rev()
        .collect::<Vec<PathBuf>>();

    RunInstructions {
        build_commands: vec![format!(
            "fsharpc --out:a.exe {} {}",
            language::join_files(other_source_files),
            main_file.display()
        )],
        run_command: "mono a.exe".to_string(),
    }
}
