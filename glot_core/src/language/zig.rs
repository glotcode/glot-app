use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{"Hello World!"});
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Zig,
        name: "Zig".to_string(),
        logo_svg_path: "/static/assets/language/zig.svg?hash=checksum".to_string(),
        file_extension: "zig".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.zig".to_string(),
            mode: "ace/mode/plain_text".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/zig:latest".to_string(),
            version_command: "zig version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![],
        run_command: format!("zig run {}", main_file.display()),
    }
}
