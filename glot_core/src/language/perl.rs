use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
print "Hello World!\n";
"#;

pub fn config() -> Config {
    Config {
        id: Language::Perl,
        name: "Perl".to_string(),
        logo_name: "perl".to_string(),
        file_extension: "pl".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.pl".to_string(),
            mode: "ace/mode/perl".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/perl:latest".to_string(),
            version_command: "perl --version | head -n 2 | tail -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("perl {}", main_file.display()),
    }
}
