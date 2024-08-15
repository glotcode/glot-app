use crate::language::EditorConfig;
use crate::language::LanguageConfig;
use crate::language::RunConfig;
use crate::language::RunInstructions;
use maud::html;
use maud::Markup;
use std::path::PathBuf;

const EXAMPLE_CODE: &str = r#"
use fmt;

export fn main() void = {
    fmt::println("Hello World!")!;
};
"#;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Hare;

impl LanguageConfig for Hare {
    fn id(&self) -> String {
        "hare".to_string()
    }

    fn name(&self) -> String {
        "Hare".to_string()
    }

    fn file_extension(&self) -> String {
        "hare".to_string()
    }

    fn editor_config(&self) -> EditorConfig {
        EditorConfig {
            default_filename: format!("main.{}", self.file_extension()),
            mode: "ace/mode/rust".to_string(),
            use_soft_tabs: true,
            soft_tab_size: 4,
            example_code: EXAMPLE_CODE.trim_matches('\n').to_string(),
        }
    }

    fn run_config(&self) -> RunConfig {
        RunConfig {
            container_image: "glot/hare:latest".to_string(),
            version_command: "hare --version".to_string(),
        }
    }

    fn logo(&self) -> Markup {
        html! {
            svg xmlns="http://www.w3.org/2000/svg" version="1.0" viewBox="0 0 18432 18432" {
                path d="M10224 936h-288l-288 144-288 144-288 432-360 360-144 360-216 360v1152l72 504 72 432 288 864 216 792 144 288 144 288v72l72 144-216 72-144 72h360v-144l72-72-216-504-216-576-216-864-288-864-72-720v-792l216-504 288-432 360-432 432-432 216-72h288l72 72 72 72v-72l72-72 144 72 216 72 216 216 288 216 144 288 144 360 144 1224 216 1296v648l72 648h72v-360l72-288 144 144 144 144h-144l-144-72v360h72v72l144-72h144v-216l-72-288 72 144 72 144v-144l72-144-72 288v216l72-72 72-144 72 144v72l144-216 72-144-72-72-72-144v144l72 72-72 72-72 72v-216l-72-216-144-360-72-360 72 288v288h-144v-432l-72-144-72-144 72 360v360l-72-72-72-72v-216l-72-288v576h-72l-72 72v-648l-72-216v-288h144v432l144-144 144-144v-216l-72-216v432h-144l-72-216v-648l72-432-72-216-72-216 72-648v-648l72 360 72 288v-648h-144l72-72v-72h576l288 144 288 144 144 144 144 216 144 360 216 432 144 720 72 792v1944l-144 72-72 72v144l144-72h72v216l72-144 72-144h-144l72-936V4104l-72-720-72-720-144-432-144-432-216-288-216-288-360-144-288-144h-648l-72 432-72 360v2016l-72-72-72-720-144-792-144-288-144-288-216-216-144-216-288-144-216-72zm2232 4896v72h-72v-72z" {
                }
                path d="M12384 1080h-72v144h72v-144M12528 1152h-72v72h72zM12672 1152h-72v72h72zM9936 1224h-72v72h72zM10800 1224h-72v216l72-72v-144M12888 1224h-72v216l72-72v-144M11016 1440h-72v144h72v-144M10512 1584h-72v72h72zM11232 1872h-72v72h72zM9144 2016h-72v72h72zM11304 2016h-72v72h72zM12240 2160l-72-216v792l72-144v-432M10728 2664l-72-576v864l144 504 144 504v72h-72l-72-72-72-72 72-72v-144l-72 72-72 72 72 360v288h216v288l-72-72v-144l-72 72-72 72-72-72-72-144v360h144v288l-72-72-144-144v-216l-72-216-72-72v-72h72l144 72v-360h-216v-72l-72-144 72 216v216h-72l-72-72 72 360 144 288 72 288 144 288v72h-72l-72-144-144-216-72-144v-216l-72-72h-72l216 504 144 504v72l-144-216-144-288-72-288-72-216-72 72-72 72h-144l-216-72v144l144 360 144 288v72h-144l-72-360-144-360v-360l72-144-72 144-72 72h-144v-504l-72 216v144l-144-72-72-72 72 216 72 216h144l216 720 216 720 72-72h72l72 216 72 216h72l-72-72v-72h72l144 72-72-144v-216l72 144 72 72 72-72v-72l72 72 72 72v-432l144 144 72 72v-72l-72-72h144v144l72-72h72v-216l-72-144 144-72h216v-288l72 144 72 72v-216l72 144 72 72-72-864v-936l-72-432-72-432-144 72h-72v-216h144v-504h-72l-144-72v144l-72-72-72-144v1080h-72v-72zm288-216v72h-72v-72zm0 144v720l-72-144-72-216 72-216v-144zm-72 792v72h-72v-72zm144 360v288l-72 72v-504zm-216 576v72h-72v-72zm216 216v72h-72v-72zm0 144v144l-72 72v-216zm-936 720v72h-72v-72zm-216 432v72h-72v-72zm144 72h72v144h-216l72-144v-72z" {
                }
                path d="M10368 2232h-72v720h72v-720M10512 2304l-72-144zv144h72v-72zM8856 2304h-72v72h72zM9648 2304h-72v72l72 144 72 144v-288zM9864 2304v288l72 144 72 144-72-288v-288zM10152 2520l-72-144v432l72-72v-216M10584 2520h-72v144h72v-144M12816 2520h-72v72h72zM9504 2592h-72v72h72zM12384 2664h-72v144h72v-144M9360 2736v288l72 144 72 144-72-288v-288zM9792 2736h-72v216l72-72v-144M12816 2736h-72v216l72-72v-144M13176 2880l-72-144v360l72-72v-144M9216 2880h-72v72h72zM10224 3024l-144-144v144l216 144 144 144v-216h-72l-72 72zM10584 2952l-72-144v360l72-72v-144M9072 2952h-72v144h72v-144M12816 3024h-72v216l72-72v-144M9792 3096h-72v72h-72v360l72-72v-72h72l72 72-72-216zM9936 3096h-72l72 144v144l72 72h72l-72-144v-144zM9216 3168h-72v144h72v-144M9072 3240h-72v144h72v-144M10656 3240h-72v144h72v-144M12240 3312l-72-144v360l72-72v-144M8568 3312h-72v216l72-72v-144M12528 3312h-72v216l72-72v-144M9288 3384h-72v144h72v-144M9576 3384h-72v72h72zM10440 3384v144l144 144 72 72-72-144-72-216zM9144 3672l-144-288v144l72 360 144 288v-288zM10296 3528l-72-144v144l72 144v144h72l144 72-72-144v-144zM13176 3456h-72v216l72-72v-144M10080 3600l-72-144v144l72 144 72 144v-216zM9360 3600h-72v216l72-72v-144M9864 3744h-72v72h72zM9936 3888h-72v144l-72 72 72 144 72 144h72v-216l-72-216zm0 216v72h-72v-72zM9576 3960h-72l72 216 72 144h72v-72l-72-144v-144zM12672 3960h-72v216l72-72v-144M10224 4032h-72v72h72zM13608 4176l-72-144v504l72-72v-288M13032 4248l-72-144v432l72-72v-216M8640 4248h-72v72h72zM9432 4248h-72v72h72zM12456 4320h-72v144h72v-144M9504 4392h-72v72h72zM9792 4392h-72v72h72zM10152 4464h-72v72h72zM9720 4608v144h72l72 72-72-72v-144zM10008 4608h-72v72h72zM9144 4968v216h72l72 72-72-144v-144zM12816 4968h-72v72h72zM12960 5040h-72v72h72zM12960 5184h-72v72h72zM13464 5328l-72-144v360l72-72v-144M13176 5400l-72-144v432l72-72v-216M13752 5400l-72-144v504l72-72v-288M7848 5760l-216-72v144l72 72-216-72h-216v72l72 72 360 216 432 144-216-144-144-144 144-72 144-72h648l-72-144v-72h-288l-144 72-72 72zM9360 5688h-72v216l72-72v-144M11088 5760h-72v216l72-72v-144M11304 5760h-72v216l72-72v-144M13104 5760h-72v216l72-72v-144M13320 5832l-72-72v144l-72 144 72-72 72-72zM13536 5760h-72v216l72-72v-144M13680 5904h-72v216l72-72v-144M7128 5976h-72l72 72v72h72v-144zM13896 5976h-72v144l-72 72 72-72 72-72zM6840 6048h-72v72l72 72 144 72 216 72-144-144-144-144zM11880 6120v-72l-216 72-216 72h72l72 72 72-72h72v72l-72 72h216v-72l72-144zM6480 6120h-72l72 72 144 72h72v-72l-72-72z" {
                }
                path d="M8496 6120h-144l72 72h144l144-72zM14472 6120h-72v72h-72v216l72-72 72-144zM11304 6264l-144-72 72 72 144 144h144v-72zM7560 6264h-72v72h72zM6264 6336h-72l72 72v72h144v-72l-72-72zM7344 6336h-144l72 72 216 72 216 144 72-144 72-72h-144l-72-72 72 72v72h-144l-72-72zM8280 6336h-72v144h360l-144-72-72-72zM11160 6408l-144-72 72 72 144 144h144v-72zM14688 6336h-72l-72 72-72 144h144l-72 72v144h144v-144l72-72h-144v-144zM6912 6408h-72l144 72 216 144h144l216 72-288-144-288-144zM8856 6552l-72-144v216l72 72h72l72-72zM10872 6480l-144-72 72 144 144 72h72v-72zM6048 6552l-288-72 72 144 144 72h-216l-216-72 72 72 144 144-144 72-72 144h-288l-216-72v144h288v72l-72 72h-288v144l144 72 216 72 144-72 216-72 72 72v72h288l-216-144-216-144h216l144 144 216 72-144-144-144-144h-504l72-72h360v-144h216l72 72 72 144h144l-72-144-144-144v-144l72-72 72-72 288 144 288 144h144l-360-144-288-216zM6768 6552l-144-72 72 72 144 144h144v-72zM9864 6552l-72-144v360h72l72 72v-144zM11160 6624h-72v72h144v-72zM7128 6696h-72v72h72zM8712 6696h-72l72 144 72 72h72v-144l-72-72zM14832 6696h-72l-72 72-72 144v72h72l72-144 72-72zM13968 6768h-72l-72 144-72 144h72l72-144z" {
                }
                path d="M5328 6840h-72v72h144l72 72-72-72v-72zM6336 6840h-72l72 144 72 144h144l-72-144-72-144zM14112 6840h-72l-72 144-72 144h144l-72 144v144h72l72-72v-144l72-144-72 72h-72v-144zM7056 6912h-72v72h72zM14760 7128h-72v504l72 504 72 144 72 144 288 288 216 288v432h144v-360l-72-360-72-72-72-72-72-504-144-576-144-144-72-216zm72 144h72l72 216 72 144-72 72-72 72h-72l-72-72v-432zM8064 7200h-72l72 72h144v-72zM6624 7344h-72v72h144v-72zM14184 7344l-72 144-72 144h144v-144l72-144zM4752 7488h-72v144h144v-144zM6480 7560h-72v72h144v-72zM14328 7560h-72l-72 144-72 216h144l72-144v-216M5112 7632h-72l72 72v72h144v-72l-72-72zM9072 7632h-144l72 144v144l144-72h144l-72-144v-72zM10296 7704l-144-72v72l216 144 288 144-144-72-72-144zM10440 7632l72 72v72h72v-72l-72-72zM11592 7632h-144l-144 72h-72l-144 144-144 72v792l144 360 144 360 288 72 288 72h216l288-144 288-72 72-144 72-144-144-432-72-432-144-216-144-144-216-144-216-72zm720 504 144 144v216h-144v72l72 144h-144v72l72 72h-288l72-144v-144l-72-72h-72v-288l72-144 144-144zm0 864v72h-72v-72zM4896 7776h-72v144h360l-144-72-72-72zM8784 7776h-72v72h144v-72zM10224 7848l-144-72v72l216 72 144 144v-72l-72-72zM4608 7848h-144v144h144l72-72 144-72zM5328 7848h-144l72 72h144l216 72 216 72-144-144-144-72zM6264 7920h-216l72 72h216l144-72zM8712 7992h-72v72l-72 144h144v-144l72-72zM8928 7992h-72v144h72v72l144-72h72l-72-72v-72zM10080 7992l144 144 144 216h72l-144-216-144-144zM6048 8064h-144v72h144l216 72-72-72v-72zM4464 8136h-72l72 72h144v-72zM4968 8136h-216l288 72 288 72h360l-216-72-216-72zM6840 8136h-72v72h144v-72zM14472 8208h-72v144l-72 72v72l72-72 72-144zM7776 8280h-72l72 72h144v-72zM8856 8280h-288v144l144-72h144v144h-216l72 72h72l216-72 216-144v-72zM9432 8280h-72v72h72zM4392 8352h-144v216h-144l-72 72h360v-72h-72l72-144 72-72zM5112 8352h-72l-288 72-216 72h360l72 72 72 72h216l216-72h-504v-144l288 72h288l-144-72-144-72zM6048 8352h-216l72 72h288l144-72zM9576 8352h-72v72h72zM10584 8352h-72v72h72zM14616 8352h-72v144l-72 72 72-72 72-72zM6984 8424h-72v72h72zM7920 8424h-144l-216 72-144 72h288l144-72 216-72zM14760 8496h-72v72h72zM7992 8568h-72l72 72h144v-72zM9144 8568h-72l-72 144-144 144h144l144-144 72-144zM9648 8568h-72v72h72zM7704 8640h-216l72 72h216l144-72zM14688 8640h-72v144h72v-144M5184 8712h-216v144l-72 72h216l288-72-72-72v-72zM6048 8712l-288 72-216 72h504l72-72v-72zM14832 8712h-72v144h72v-144M4248 8784h-144v72l-72 72h144l72-72 144-72zM4536 8784h-72v144h144v-144zM7992 8784h-72l72 72h144v-72zM9288 8784h-72l-72 72v288l72 144 144-144 144-144h-144l-144 72 72-72 72-72v-144zM9648 8784h-72v72h72zM7704 8856h-144l72 72h144l144-72zM9792 8856h-72v72h144v-72zM15048 8856h-72l-72 72v72h72l72-72zM14760 8928h-72v72h72zM4464 9000h-144l72 72h144l144-72zM7920 9000h-72v72h144v-72zM8136 9000h-72v72h72zM14544 9000h-72v144h72v-144M5184 9072h-72v72h144v-72zM8928 9072h-72v72l-72 72 72-72h144v-72zM9792 9072h-72v72h144v-72zM14904 9072h-72v72h72zM4032 9144h-72l72 72h144v-72zM4968 9144h-72l-360 72-288 72h504v216l72 216h72l144-72h72l144-72-72-72-72-72h216v-216l-216 72h-216l72-72 144-72zM5760 9144h-72l-72 72v72h72l72-72zM8208 9216h-216l72 72h216l144-72zM14616 9216h-72v144h72v-144M6840 9288h-72v72h144v-72zM7920 9288h-72v72h72zM8928 9288h-72l-72 72v72h72l72-72zM9432 9288h-72l-72 144-144 144v216h144l72-144v-144l72-72v-72l72-72zM9720 9288h-72v72h144v-72zM5832 9360h-72v72h72zM10008 9360h-72v72h144v-72zM14760 9360h-72v72h72zM14976 9360h-72v72h72zM4032 9432h-144v72l-72 72h144l72-72 144-72zM6984 9432l-144 72-144 72h216l72-72zM8208 9432h-144v72l-72 72 216-72h144v-72z" {
                }
                path d="M4392 9504h-144v72l-72 72h144l72-72 144-72zM7848 9504h-72v72h144v-72zM9000 9504h-72v144h72v-144M15120 9504h-72v144l-72 144v72h72l72-144v-216M15552 9504h-72v72l-72 72h144v-144M6624 9576h-72v72h72zM7344 9576h-72v72h144v-72zM8496 9576h-72l-216 72-216 72h360l144-72 144-72zM7056 9648h-72l-144 72-72 72h144l72-72 144-72zM10008 9648h-144l72 72h144l144-72zM4176 9720h-144l-216 72-144 144h72l288-72 288-144zM4392 9720h-72l72 72v72h144v-144z" {
                }
                path d="M5112 9720h-216v72h-72l72 216 72 144h144v144h-72l-72-72-216 144-216 144h-144l144-72 144-72 72-144 72-72h-216v72l-72 72h-504l72-72h72l-72-144v-72h216v72l-72 72h72l72 72 72-72 144-144h-216l-216-72-144 72h-144l-144 144-144 144v72l144-72 72-72v216l-144 144-144 72h216v144l-144 72-144 72v144l144-72 144-72v144l72 72h-360v144l-72 72 72 72v72h-72l-72 72 72 72v72l144-72 72-144-72 216-72 144 72 72 72 72-72 144v144h144v72l-72 144h72l144-72 216-72-216 144-144 216 72 72 72 72-72 144v72h72l216-144 216-72-216 144-144 144 72 288 72 216 144 216 216 216-72 72-72 144h-504l-504 72h1152v-144h144l-72 72v144h288v216h-144l-144 72h-936l360 72 360 72h-216l-144 72h1152v-144h-216l-216 72v-144h360l144 72h144v216h-360l-360 72h-360l-360 72h720l720-72h72l144-72v216h-432l-360 72h1008v-144h144v216h-432v72h360l216 72 144-72 144-72 72 144v144l144-72h72v144H5472l-1008 72h2088l72-144 72-144h144v72l-72 144 216 72 216 72h360l-648 72-576 72h1584l-144-72-144-72h216l144-72 72 72 72 72 72-72 144-72 216 72 216 72v-144h288l360 72v144h-504l-504 72h1872v-72l-72-72h-648l72-72h72l144-144 144-72v216h144v-216h144v216l72-72 144-144h144v144l144-72 72-144 72 144v72h288l72-144 144-72 72-72 72 144 144 72v-72l72-72h144l144-72v216h144v-216l72-72h144v216h144v-144l72-144h72l144 72v-144l72-216 72 144v72l144-144 72-144 72 72h144l-72-144v-144h144v72l72 72v-216h216v144h144v-216l-72-144h144l72 72 72 72-72-216v-216l72 144 144 144v-144l-72-216h144l72 72 72 72v-144l-72-72h-72v-144h216v72l72 72h72v-72l-72-72-72-144v-72l72-144 144 72h144l-144-72-72-72 72-144v-72l144 72h144l-72-72-72-144v-72l72-72h-216v-144h144l144 72v-144h-216v-144h288v-72l72-72h-72l-72-72h144l-72-216v-144l72-72 144-72h-216v-144h288l-144-72-72-72-72 72h-72l-72-72v-72h72l72 72v-144l-144-72h-72l-72 72-72 144h-144v-216l72-144 288-360 360-288h144l-144-144-144-72-216 216-288 216-216-144-216-216h-216v144l144 216 216 144v432l72 360h-144l-72-72v216l-72-144-72-216-72 216-72 144v-144l-72-216-72 216v216h-144v-288h-72l-216 216-144 144v-216h-288v216h-144v-432l-72 144v72l-72 144v72l-144-216-72-216v288h-144v-360l-72 144v144h-144v-144l-72-216v432l-72-72h-72v-360h-144v288h-216v-144l72-72 72-144v-144l-144 216-72 144h-144v-144l72-144h-144v72l-72 144h-144l72-216v-216l-144 144-72 144-72-72v-72l-72-144-144-72-72 72-144 72v-360l-72 72-144 72v-72h-72l144-144 72-144h-144l-144 216-216 216h-144l72-72 144-144 144-216 144-216h-144l-72 72-72 72v-144l72-144h-144v72l-72 72h-72v-72l72-72 72-72v-144l-144 72h-72l72-72v-144h-72l-144 144-72 72v-144l144-144 144-144h-144l-72 72-72 144-72 144h-216l-72 144-72 72 72-72 144-72h72l72 72v288h144l216-72-216 144-216 144v144l144-72 216-144v-72l72-72v288h72l72-72-72 72v144h-144v-144l-144 72-144 72v144l72-72 72-72h144l-72 72-72 72v144l144-72 72-72v144h-72l-72 72 72 144v72l72-72 72-72v-144l72-72 144-72 144-72v72l-144 288-216 216v144l72-72 144-144 72-144 72-144v72l72 72-144 216-72 216 72 72h72l-72 360v288l72-144 72-144h72l-72 432-72 432h-144v144l72 144h-144l-72-72-72-72-72 216-144 288h-144l72 144v216h-144v-360l-72-288 72-216 72-216-144 144-72 144v432l72 360h-144l-72 72v216l-72 72h-72v-216l72-216h-144v144l-72 216h-144v-288l72-288h216v-72l-72-144 144-72 72-144v-216l72-216-72 216-144 144-216 288-216 216h-144l-72 216-72 216-72 72h-72l144-216 72-288v-216h288l72-72-72-144v-72h-288l-216 72-144 72h-144v-72l72-144-72 72h-144l-72-72-72-144 144-144 72-216v-288l-144 288-144 216 72 72v72h-72l-144-72v72h-72v288l-72 216 72-72 144-144v216l-72 72-144 72-72-72-144-144 72-216 72-216v-288l-144 432-144 360v144l144-72h144l-216 144-144 144-72 216-72 216-72-72v-72l72-216 144-216v-288l-216 360-144 288h-72v-72l144-288 144-288v-144l-216 216-144 216 72-144 72-216v-144l-72 72-144 72v-72h-72l72-144v-72h-144l-72 144-144 216h-360v-144h216l144-144 144-144v-144h360l-72 144v144l72-72h144v216h288l72-288 72-216-72-72-72 144v144h-144l72-144 72-216h-72v-72l216-288 216-360h-72l-72-72-144 72-144 72-144 72h-72v-216l-72-216h144v-72h-72l-144 72-72 72h-72v-72l216-144 144-144h-144l-144 72-144 144v-72h-72l-144 288-216 288h-72l72-144v-144h-144l72-144v-144l144-144 216-144h-144l-72 72v-144l72-72 144-72-216 72-144 144v216l-144-72-72-144v-144l216-144 216-144h-144l-72 72-72 144h-144l144-216 216-144-144 72-144 72-72-72h-72l72-72 72-72 72-72 72-144-216 72h-288l-216 72-216 144 72-72v-144l144-72h144l72-72h72l216-72 288-144h-360l144-72 144-72h-432l72-72h144v-216zm72 72v72h-72v-72zm-1008 576h216l-144 72h-216l-72-72zm0 144h72v72l-72 72h-288l72-72 144-72zm1080 72h72v72h-144v-72zm-216 72h72v216h-144l-72 72h-216v-144l144-72zm-432 216 72 144v72h-72l-72-72h-144l72-144v-144zm-432-72h72v72h-144v-72zm-144 72v72h-72v-72zm1008 144h72v72l-144 72-216 144v-216h144zm-504 216v72h-72v-72zm144 0v72l-72 72v144l-72-72h-72l72-72zm-1008 72v144h-144l72-72v-72zm504 0h216l-144 72-72 72h-288l72-72v-72zm792 72h72l-72 72-72 72h-72v-144l72-72zm5544 0h72v72l-144 288-144 216v-144l72-216 72-216zm-6696 72v72h-72v-72zm1296 72h72v144l-216 72-144 72-72 72h-72l144-144 216-216zm5616 0h144l-144 72h-72v216l-144 144-72 72 72-144 72-216 72-72v-72zm-6408 72v72h-72v-72zm6552 72v72l-144 216-72 288h-72v-72l144-216 72-288zm-6336 72h72v72h-144v-72zm5616 0v72h-72v-72zm-4968 72h72l-144 72-72 144h-144l72-144 72-72zm-1512 72v72h-72v-72zm216 0v72h-72v-72zm2232 0-72 144v72l72-72h72v72l-72 72-72 144v144h72l72-72-72 144v144l-72 72h-72l72-144v-216l-72 144-72 72v-144l-72-144v-144l72 144 72 72v-144l72-72-72-72h-72l72-144 72-72zm5688 72v72h-72v-72zm1800 0v72h-72v-72zm1296 0v72h-72v-72zm-9720 72h72v72l-72 72h-144v-144zm9432 72 72 144v216l-72-72-72-144v-288zm-10656 72-72 72-72 72h-144v-144h144l144-72zm1008-72v72h-72v-72zm6624 72v144l-72 72v-360zm360 0v144l-72 72v-360zm1656-72v144l-72 72v-216zm720 0v144h-72v-144zm576 72h72v144h-72v-72l-72-72zm-10296 72v144h-72v-144zm648 0h72v72h72l-144 144-72 72h-216l72-72v-72l72 72h72v-216zm288 0h72v72h-144v-72zm720 0v72h-72v-72zm6624 0h72v504h-72v-288l-72-216zm-1152 72v72h-72v-72zm2664 0v72h-72v-72zm-8856 144-72 144-144 72-72-72 72-144 144-72zm-864 0v72h-72v-72zm1944 0v72h-72v-72zm4104 72v144l-72 72h-72v360l72-144v-144h72l72-72v-288h144l-72 72v72l144 144 144 144-72 216v288h72l72-72v216h-216l-288 72v-360l-72 216-72 144h-72v-216l72-216-144 72h-72v-216l72-216 144-72 72-72v-288zm2736-72v144h-72v-144zm1440 0v72h-72v-72zm-10512 72v72h-72v-72zm1296 0h72v144l72 144-216 144-144 144-72-72 72-72 144-144v-72l-144 72h-72l72-144 144-144zm6264 0v144h-72v-144zm-7200 72h72v72h-144v-72zm1656 144 144 144-72 72v72l-72-72v-144l-144 72h-72l72-144 72-144zm4824-144v144h-72v-144zm144 0h72v144h-72v-72l-72-72zm-7416 72v144h-144l72-72v-72zm8712 0h72v144h-216l72-72v-72zm-8064 72v72h-72v-72zm288 0v144l-432 360-360 288 72-144 72-144 288-216 288-288zm5400 0h72v144l-72 144-72 72v-360zm4464 0h72v72h-144v-72zm-576 72h72v144h-72l-72 72v-216zm216 0 144 72v216l-72-72v-144h-72l-72-72zm-2952 144v144h-72v-144zm144 0 72 72v144l-72-72h-72v-144zm2016 72 144 144v144l-144-144-144-72v-144zm-2376 72v72h-72v-72zm1800 0 72 72v144l-72-72h-72v-144zm-2808 144 72 72-72 216v288h-72l-72-72h-144l-144-72v-144l144 72 72 72 72-72 72-144v-288zm3240-72v72h-72v-72zm-1080 72v72h-72v-72zm144 0v72h-72v-72zm1800 0h72l72 72 72 144h-216v-216m-2736 144 144 144-72 216v144l-72-144-72-144v-288zm1728-72v72h-72v-72zm-5184 72h72v216l-144 72-144 72v-216l72-72 72-72zm2304 0v144h-72v-144zm-2952 216v216l-72 72h-72l-72-72 72-144 72-144zm3888 0v72h-72v-72zm720 0v72h-72v-72zm2088 0 72 72v216l-72-72-72-144v-72zm-9864 72v72h-72v-72zm3312 0h72v144l-72 144-72 144v-72l-72-72 72-144v-144zm2952 0h144v144l144-72h72v144h-72l-72 72-144-144-144-144zm-3456 144 72 72-72 144-144 72v-288h72v-72zm-1152 0v144h-144l72-72v-72zm5184 0v144h-72v-144zm288 0v144l-72 72v-216zm504 0h72v72h-144v-72zm-5832 144h72v72l-144 288-144 216h-72v-72l144-216zm1224 72 72 72v144l-72-72h-72v-288zm648-72h72v144h-144v-144zm648 0v72h-72v-72zm1152 72 72 72 72 72h144v-72l72-144v216l72-72h72l72 72 72 72v144h-72l-144-72v144l-72-144-72-144v216l-72-72h-144v144l-72 144v-360h-144l72-144v-144zm2160-72v144h-72v-144zm-288 72h72l72 72v72h-72v-72zm-4752 72v72l-72 144-72 144h-72v-72l72-144 72-144zm1584 0h72v216l-72 72h-144v-144l72-144zm3672 0v144h-72v-144zm360 0v144h-72v-144zm-4536 72v72h-72v-72zm5544 0v72h-72v-72zm-7200 72v72l-72 144-72 144h-144l144-216 72-144zm4320 0 144 72v432h-144v-360l-72 144-72 72v-360zm-3456 72v144h-144l72-72v-72zm3888 72v72l144-72h144v144l-72 144-72 72v-216h-72l-72 72-72-72-72-72 72-72v-72zm576 72v144l72 72h144l-72 216v144l-72 72h-72l-72-288v-288l-72 72-72 72v-216l72-72 144-72zm-2448-72v144h-72v-144zm-2304 72h72v72h-144v-72zm1800 0v72h-72v-72zm-1080 72v72h-72v-72zm4680 72h72v216h-216v-72l-72-72h72v-72zm360 0v72h-72v-72zm288 0h72v144l72 72-72-72h-72v-144m-5256 72h72v144h144l144 72h-288l-216-72v-72h72v-72zm4320 0v144h-72v-144zm-3456 72h72v72h-144v-72zm1512 0v144h-72v-144zm648 72h72l-72 72v144h-72v-216zm288 72h72v360h-144v-216l-72-144zm432 0h72v144h-72l-72 72v-216zm-1368 144v72h-72v-72zm648 144v72h-72v-72zm-4680 72v144h-144l72-72v-72zm3600 0h72v144h-144v-144zm864 0v72h-72v-72zm-3384 432v72h-72v-72z" {
                }
                path d="M10872 12816h-72l-72 144v216l72 144 144 72v-216l72-144v-144l-72 144-144 144 72-144zM5688 9720h-72v72h144v-72zM6624 9792h-72v72h144v-72zM8640 9792h-72l-216 72-144 72h288l72-72 144-72zM15624 9792l-144 72-72 72 72 72 72-72zM7056 9864l-144 72-72 72h144l72-72zM9072 9864h-72v72l-72 72h144l72-72v-72zM5688 9936h-72v144l144-72h216l-144 72-144 144 72 144 72 216 216-144 288-72v-144l-144 72-144 72h-72l144-144 144-144-216-72-216-72zM10152 9936h-72v72h72zM6696 10008h-72v72h144v-72zM8712 10008h-72l-288 144-288 72 216-72h288l72-72 144-72zM11736 10008h-72l-144 144-72 144 144-72 216-144v-72zM12096 10008h-72l-144 144-72 144 144-72 216-144v-72zM12672 10008h-72l-144 216-144 144 144-72 144-72v-144zM15624 10008h-72l-72 72v144h72l72-72 72-144zM7128 10080l-216 144-216 72v72l216-144 216-72zM12312 10080h-72l-72 144-72 72 144-72 144-72v-72zM10368 10296h-72l72 72 144 72h144l-144-72-72-72zM15552 10296h-144l72 72 72 72 72-72 72-72zM8064 10368l-144 72-72 72h144l72-72zM8424 10368h-72v72h144v-72zM6408 10512v-72l-288 216-288 144h216l-144 72-72 144h216l216-144 216-144v-72l-144 72-144 72h-72l144-144zM7632 10440h-72v72h72zM8712 10440h-72v72l-72 144h144v-144l72-72zM7056 10656h-72l-72 144-72 72 72-72 144-72zM7488 10656h-72l-144 72-72 144 72 72 72-144zM8208 10656h-72l-72 72v216l72 72 72-144 72-216zM9000 10656h-72l-72 144-72 144h72l72 72v-144l72-144zM8424 10728h-72v144l-72 72v72l72-72 72-144zM15552 10800l-144-72 72 144v72h144v-72l72-72zM6480 10872l-288 144-216 72v72l72 144 72 72 144-72 216-144v-288M8568 10872h-72v72h-72v216l72-72 72-144zM7416 10944h-72v72l-72 72h144l72-72v-72zM6912 11016h-72l-72 72v72h72l72-72zM8712 11016h-72l-72 72v144l72 72 72 144 72-144 72-216-72 144-144 72v-144zM15336 11088l-72-72 72 144 72 144h144l-72-72v-144zM12744 11088h-72l-144 144-72 144 144-72 144-72v-144M13032 11088h-72l-144 144-72 144 144-72 144-72v-144M12384 11160h-72v72l-72 72 72-72h144v-72zM13248 11160h-72l-144 144-72 144 144-72 216-144v-72zM8064 11232h-72v72h72zM9072 11232h-72l-72 144-72 144v72h72l72-144 72-144zM13608 11232h-72v72l-72 72 72-72h144v-72zM15264 11304l-72-144v360h72l72 72v-216zM7056 11304h-72l-72 72-72 144v72h72l72-144 72-72zM9360 11304h-72v144h72v-144M13392 11376h-72v72h72zM7200 11520l-72-72v72l-72 72v72h144v-144M7488 11520h-72l-72 144-144 144v72h72l144-144 72-144zM7848 11592l-72-72-144 288-216 216h72l72-72 144-144zM8352 11520h-72v72h72zM8208 11592h-72v72h72zM8496 11592h-72v72h72zM9072 11592h-72v144l-72 72 72-72 144-72v-72zM9360 11664h-72l-144 144-72 144 144-72 144-144zM9576 11664h-72l-144 216-144 144v144h216l-72-72v-72l72-216zM8424 11736h-72l-72 72v72h72l72-72zM8640 11736h-72l-72 144-72 72 72 72 72-144zM6624 11808h-72v72h144v-72z" {
                }
                path d="M9648 11808h-72l-72 144-72 72 72 72h72l-72 72v144h144l144 72v144l144-144 72-216v-72l-144-144-144-144zm0 144v72h-72v-72zM7920 11880h-72l-72 144-144 144v72h72l144-144 72-144zM8136 11880h-72l-144 288-144 216v72l144-72 72-72 72-216 72-144zM8784 11952h-72l-72 72v72h72l72-72zM8856 12096h-72l-72 72v72h72l72-72zM7128 12168h-72l-144 216-144 216v72h144l144-288 144-216zM8496 12168h-72v216l72-72v-144M9072 12312l-72-72-72 144-144 144v144l72 72h72v-72l-72-72 144-144zM7344 12312h-72l-144 216-216 216 72 72 144-144 72-144 72-72zM8208 12312h-72l-72 72-72 144v72h72l72-144 72-72zM8640 12384h-72v144h144v-144zM7488 12456h-72l-72 144-144 144v72h144l72-216 144-144zM8352 12528v72h-72v576h144v-648zM9216 12528h-72l-72 72v72h72l72-72zM9504 12528h-72v144l-72 72v144l72-144 144-144v-72zM3312 12600h-288l144 72h288l144-72zM9792 12600h-72l-72 144-72 144v72h72l72-144zM2520 12672h-72v72h72zM7920 12672h-72v216l72-72v-144M9216 12744h-72v72l-72 72h144v-144M10008 12744h-72v72l-72 144h144v-216M8136 12816h-72v72l-72 72h144v-144M8712 12816h-72l-72 72-72 144v72l72 72 72-144zM3384 12888h-360l144 72h432l216-72zM2304 12960h-72v72h72zM2592 12960h-144l72 72h144l144-72zM8856 12960h-72v144l-72 72v72h72l72-144 72-144zM7848 13032h-72v72h72zM3600 13104l-432 72-432 72h864l72-72v-72zM7992 13104h-72v72h72zM9864 13104h-72v72h144v-72zM9576 13176l-72 144v72l-72 72v72h144v-144l72-144zM2304 13248h-72v72h72zM3384 13320h-360l144 72h432l216-72zM3672 13464h-144l-288 72-216 72h432l144-72 216-72zM2736 13608h-144l72 72h144l144-72zM9144 13680l-72-144v360l72-72v-144M3600 13680h-288l144 72h288l216-72zM3960 13968h-144l-432 72-432 72h792l144-72 216-72zM3960 14112h-72l-144 72-72 72h216l216-72v-72zM3240 14184h-216l72 72h288l144-72zM3600 14184h-72v72h72zM3168 14328h-72v72h72zM4104 14544h-360l-288 72-288 72h648l360-72 360-72zM3240 14760h-288l144 72h288l144-72zM3744 14904h-72v72h144v-72zM3528 15120h-144l72 72h144l144-72zM13824 15192h-216l72 72h288l144-72zM4608 15264l-216 72-216 72h432v-144M13392 15264h-144l72 72h144l144-72zM5184 15408h-72v72h72zM5328 15408h-72v72h72zM4392 15480h-504l216 72h576l288-72zM13032 15552h-72v72h72zM13320 15552h-216v72h216l144 72v-144zM13032 15768l-432 72-360 72h864v-72zM12024 15840h-72v72h72zM11304 15984h-504l504 72 504 72h-216l-144 72h-360l-360 72h864l72-72h144v-216zM8424 16272h-720l360 72h720l432-72zM9288 16272h-72v72h72zM10224 16272h-72v72h72zM10368 16272h-72v72h72zM6912 16344h-432l216 72h432l288-72zM12960 16344l-504 72-432 72h864l72-72zM5760 16416h-360l144 72h360l216-72zM11880 16416h-72v72h72zM4968 16488h-216l72 72h216l144-72zM10512 16488h-792l360 72h792l432-72zM11664 16488h-72v72h72zM9000 16560h-360l144 72h360l216-72zM7992 16632h-288l144 72h288l144-72zM7272 16704h-144l72 72h144l144-72zM6552 16776h-144l72 72h144l144-72zM6840 16776h-72v72h72zM5904 16848h-72v72h72zM12096 16848h-288l144 72h288l144-72zM11376 16920h-432l216 72h432l216-72zM10080 16992h-504l216 72h576l288-72zM8784 17064h-504l216 72h504l288-72zM7848 17136h-288l144 72h288l144-72zM7128 17208h-144l72 72h144l144-72zM10728 17424h-216l72 72h288l144-72zM10008 17496h-360l144 72h360l216-72z" {
                }
            }
        }
    }

    fn run_instructions(&self, main_file: PathBuf, _other_files: Vec<PathBuf>) -> RunInstructions {
        RunInstructions {
            build_commands: vec![format!("hare build -o a.out {}", main_file.display())],
            run_command: "./a.out".to_string(),
        }
    }
}
