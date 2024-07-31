use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
int main () {
    StdIO::printf ("Hello World!");
    return 0;
}
"#;

pub fn config() -> Config {
    Config {
        id: Language::Sac,
        name: "SaC".to_string(),
        logo_svg_path: "/static/assets/language/sac.svg?hash=checksum".to_string(),
        file_extension: "sac".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.sac".to_string(),
            mode: "ace/mode/sac".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/sac:latest".to_string(),
            version_command: "sac2c -V | head -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![format!("sac2c -t seq -o a.out {}", main_file.display())],
        run_command: "./a.out".to_string(),
    }
}
