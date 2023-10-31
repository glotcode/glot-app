use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use crate::util::file_util;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
using System;
using System.Collections.Generic;
using System.Linq;

class MainClass {
    static void Main() {
        Console.WriteLine("Hello World!");
    }
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Csharp,
        name: "C#".to_string(),
        logo_name: "csharp".to_string(),
        file_extension: "cs".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.cs".to_string(),
            mode: "ace/mode/csharp".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/csharp:latest".to_string(),
            version_command: "mcs --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = file_util::filter_by_extension(other_files, "cs");

    RunInstructions {
        build_commands: vec![format!(
            "mcs -out:a.exe {} {}",
            main_file.display(),
            file_util::join_files(other_source_files),
        )],
        run_command: "mono a.exe".to_string(),
    }
}
