use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
print("Hello World!");
"#;

pub fn config() -> Config {
    Config {
        id: Language::Lua,
        name: "Lua".to_string(),
        logo_svg_path: "/static/assets/language/lua.svg?hash=checksum".to_string(),
        file_extension: "lua".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.lua".to_string(),
            mode: "ace/mode/lua".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/lua:latest".to_string(),
            version_command: "lua -v".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("lua {}", main_file.display()),
    }
}
