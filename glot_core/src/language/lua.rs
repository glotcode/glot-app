use crate::language::Config;
use crate::language::EditorConfig;
use crate::language::Language;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
print("Hello World!");
"#;

fn logo() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" preserveAspectRatio="xMidYMid" {
            path fill="#00007D" d="M225.85 128.024c0-54.024-43.846-97.87-97.87-97.87-54.023 0-97.869 43.846-97.869 97.87 0 54.023 43.846 97.869 97.87 97.869 54.023 0 97.869-43.846 97.869-97.87" {
            }
            path fill="#FFF" d="M197.195 87.475c0-15.823-12.842-28.666-28.665-28.666s-28.666 12.843-28.666 28.666 12.843 28.665 28.666 28.665 28.665-12.842 28.665-28.665" {
            }
            path fill="#00007D" d="M254.515 30.154c0-15.823-12.842-28.665-28.665-28.665s-28.665 12.842-28.665 28.665c0 15.824 12.842 28.666 28.665 28.666s28.665-12.842 28.665-28.666" {
            }
            path fill="#FFF" d="M61.25 113.756h8.559v55.654h31.697v7.526H61.25zM116.946 130.874v30.579q0 3.527 1.09 5.763 2.01 4.13 7.497 4.13 7.875-.001 10.723-7.226 1.55-3.871 1.55-10.624v-22.622h7.74v46.062h-7.31l.086-6.795q-1.478 2.623-3.674 4.43-4.346 3.612-10.55 3.613-9.665 0-13.166-6.581-1.9-3.525-1.9-9.419v-31.31zM182.88 149.06q2.665-.343 3.57-2.233.514-1.035.515-2.979 0-3.971-2.812-5.763t-8.047-1.792q-6.053 0-8.585 3.285-1.417 1.816-1.846 5.403h-7.225q.215-8.54 5.52-11.883t12.307-3.342q8.119 0 13.188 3.096 5.026 3.097 5.026 9.635v26.538q0 1.204.495 1.934.494.73 2.086.73.516 0 1.16-.064.647-.064 1.377-.193v5.72q-1.807.515-2.752.644-.947.13-2.58.13-4 0-5.807-2.839-.946-1.505-1.333-4.257-2.367 3.097-6.796 5.376-4.43 2.278-9.763 2.278-6.409 0-10.472-3.887-4.065-3.887-4.065-9.73 0-6.4 4-9.922t10.494-4.34zm-16.302 20.913q2.452 1.932 5.807 1.931 4.084 0 7.913-1.889 6.451-3.134 6.451-10.263v-6.226q-1.416.906-3.648 1.51t-4.378.861l-4.679.602q-4.206.558-6.326 1.76-3.59 2.017-3.59 6.436 0 3.347 2.45 5.278" {
            }
            path fill="#929292" d="m132.532 255.926-.102-2.935c3.628-.127 7.287-.413 10.873-.85l.356 2.914c-3.67.448-7.414.74-11.127.87m-11.162-.09c-3.707-.19-7.445-.545-11.111-1.054l.403-2.908c3.582.497 7.236.843 10.858 1.029zm33.3-2.618-.61-2.872c3.545-.752 7.097-1.67 10.559-2.73l.86 2.807a128 128 0 0 1-10.81 2.795m-55.39-.454c-3.613-.829-7.233-1.83-10.761-2.973l.905-2.793a125 125 0 0 0 10.512 2.904zM176 246.69l-1.103-2.721a125 125 0 0 0 9.916-4.533l1.336 2.615A128 128 0 0 1 176 246.69m-97.945-.809a128 128 0 0 1-10.079-4.811l1.38-2.592c3.2 1.704 6.514 3.285 9.847 4.7zm117.802-9.34-1.56-2.488a126 126 0 0 0 8.982-6.19l1.77 2.343a129 129 0 0 1-9.192 6.334m-137.5-1.144a129 129 0 0 1-9.088-6.487l1.808-2.314a126 126 0 0 0 8.88 6.34zm155.3-12.299-1.966-2.18c2.692-2.427 5.31-5 7.78-7.649l2.147 2.003a130 130 0 0 1-7.962 7.826M40.777 221.66a129 129 0 0 1-7.83-7.958l2.18-1.966a127 127 0 0 0 7.652 7.776zm188.094-14.876-2.313-1.808a126 126 0 0 0 6.343-8.878l2.461 1.602a129 129 0 0 1-6.491 9.084m-203.037-1.686a129 129 0 0 1-6.338-9.189l2.487-1.56a126 126 0 0 0 6.194 8.978zm215.206-17.015-2.591-1.38c1.705-3.2 3.288-6.513 4.705-9.845l2.702 1.149a128 128 0 0 1-4.816 10.076m-227.058-1.878a128 128 0 0 1-4.645-10.148l2.72-1.104a125 125 0 0 0 4.538 9.914zm235.788-18.66-2.792-.907a125 125 0 0 0 2.91-10.51l2.861.658a128 128 0 0 1-2.979 10.759M5.6 165.537a127 127 0 0 1-2.8-10.807l2.872-.61a125 125 0 0 0 2.735 10.557zm249.175-19.73-2.908-.405c.499-3.58.847-7.233 1.033-10.857l2.933.152a129 129 0 0 1-1.058 11.11M.957 143.721a129 129 0 0 1-.876-11.127l2.935-.104c.127 3.627.416 7.285.855 10.873zm252.035-20.085c-.126-3.62-.414-7.28-.856-10.876l2.914-.358c.452 3.681.747 7.427.876 11.132zM3.098 121.581l-2.932-.148c.188-3.708.54-7.447 1.047-11.112l2.909.402c-.496 3.582-.84 7.235-1.024 10.858M250.335 102a126 126 0 0 0-2.732-10.563l2.808-.858a129 129 0 0 1 2.796 10.81zM6.088 99.996l-2.862-.656a128 128 0 0 1 2.968-10.762l2.794.905a125 125 0 0 0-2.9 10.513m237.874-18.845c-1.358-3.36-2.88-6.7-4.525-9.928l2.616-1.333a129 129 0 0 1 4.631 10.161zM12.802 79.26l-2.703-1.146a128 128 0 0 1 4.806-10.082l2.592 1.379a125 125 0 0 0-4.695 9.849m10.233-19.25-2.462-1.6a129 129 0 0 1 6.483-9.091l2.314 1.807a126 126 0 0 0-6.335 8.883m13.416-17.185-2.15-2a129 129 0 0 1 7.954-7.835l1.968 2.18a127 127 0 0 0-7.772 7.655m16.177-14.61-1.772-2.34a129 129 0 0 1 9.186-6.343l1.562 2.486a126 126 0 0 0-8.976 6.198m143.494-5.099-.16-.103 1.596-2.464.155.1zm-9.568-5.627a126 126 0 0 0-9.854-4.682l1.143-2.704a128 128 0 0 1 10.085 4.792zm-115.471-.864-1.34-2.613a128 128 0 0 1 10.146-4.65l1.105 2.72a125 125 0 0 0-9.911 4.543m95.392-7.623a126 126 0 0 0-10.517-2.9l.656-2.862c3.614.828 7.236 1.827 10.765 2.968zM91.27 8.424l-.862-2.807a128 128 0 0 1 10.806-2.805l.612 2.871a125 125 0 0 0-10.556 2.741m53.958-4.296c-3.59-.5-7.244-.846-10.862-1.03l.15-2.932c3.702.188 7.443.543 11.117 1.054zm-32.646-.249-.36-2.914c3.67-.452 7.414-.748 11.127-.881l.105 2.934c-3.629.13-7.286.42-10.872.861" {
            }
        }
    }
}

pub fn config() -> Config {
    Config {
        id: Language::Lua,
        name: "Lua".to_string(),
        logo: logo(),
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
