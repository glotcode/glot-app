use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
print_endline "Hello World!"
"#;

pub fn config() -> Config {
    Config {
        id: Language::Ocaml,
        name: "Ocaml".to_string(),
        logo_name: "ocaml".to_string(),
        file_extension: "ml".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.ml".to_string(),
            mode: "ace/mode/ocaml".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/ocaml:latest".to_string(),
            version_command: "ocaml --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files: Vec<PathBuf> = language::filter_by_extension(other_files, "ml")
        .into_iter()
        .rev()
        .collect();

    RunInstructions {
        build_commands: vec![format!(
            "ocamlc -o a.out {} {}",
            language::join_files(other_source_files),
            main_file.display()
        )],
        run_command: "./a.out".to_string(),
    }
}