use crate::language;
use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
IO.puts "Hello World!"
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" space="preserve" viewBox="0 0 100 100" {
            path d="M57.221 24.648c7.321 15.719 26.377 22.286 24.654 42.742-2.029 24.092-19.164 30.145-28.638 30.576s-27.561-2.907-32.514-25.623C15.161 46.828 39.456 7.638 53.452 2.039c-.538 6.352.819 16.277 3.769 22.609M44.761 89.69c6.407 1.331 11.317 2.256 11.899-.324.877-3.884-14.063-6.075-24.049-7.156 2.997 3.162 9.048 6.835 12.15 7.48" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Elixir,
        name: "Elixir".to_string(),
        logo_svg_path: "/static/assets/language/elixir.svg?hash=checksum".to_string(),
        logo: logo(),
        file_extension: "ex".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.ex".to_string(),
            mode: "ace/mode/elixir".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/elixir:latest".to_string(),
            version_command: "elixirc --version | tail -n 1".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, other_files: Vec<PathBuf>) -> RunInstructions {
    let other_source_files = language::filter_by_extension(other_files, "c");

    RunInstructions {
        build_commands: vec![],
        run_command: format!(
            "elixirc {} {}",
            main_file.display(),
            language::join_files(other_source_files),
        ),
    }
}
