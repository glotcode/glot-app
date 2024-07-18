use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use std::path::PathBuf;

const EXAMPLE_CODE: &'static str = r#"
section .data
    msg db "Hello World!", 0ah

section .text
    global _start
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 13
    syscall
    mov rax, 60
    mov rdi, 0
    syscall
"#;

pub fn config() -> Config {
    Config {
        id: Language::Assembly,
        name: "Assembly".to_string(),
        logo_svg_path: "/static/assets/language/generic.svg?hash=checksum".to_string(),
        file_extension: "asm".to_string(),
        editor_config: EditorConfig {
            default_filename: "main.asm".to_string(),
            mode: "ace/mode/assembly_x86".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        },
        run_config: RunConfig {
            container_image: "glot/assembly:latest".to_string(),
            version_command: "nasm --version".to_string(),
        },
    }
}

pub fn run_instructions(main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
    RunInstructions {
        build_commands: vec![
            format!("nasm -f elf64 -o a.o {}", main_file.display()),
            "ld -o a.out a.o".to_string(),
        ],
        run_command: "./a.out".to_string(),
    }
}
