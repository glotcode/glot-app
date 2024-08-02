#[derive(Clone, serde::Serialize, serde::Deserialize, PartialEq, Default)]
#[serde(rename_all = "camelCase")]
pub enum EditorTheme {
    // Bright themes
    Chrome,
    Clouds,
    CrimsonEditor,
    Dawn,
    Dreamweaver,
    Eclipse,
    GitHub,
    SolarizedLight,
    #[default]
    TextMate,
    Tomorrow,
    XCode,
    Kuroir,
    KatzenMilch,
    // Dark themes
    Ambiance,
    Chaos,
    CloudsMidnight,
    Cobalt,
    IdleFingers,
    KrTheme,
    Merbivore,
    MerbivoreSoft,
    MonoIndustrial,
    Monokai,
    PastelOnDark,
    SolarizedDark,
    Terminal,
    TomorrowNight,
    TomorrowNightBlue,
    TomorrowNightBright,
    TomorrowNightEighties,
    Twilight,
    VibrantInk,
}

impl EditorTheme {
    pub fn label(&self) -> String {
        match self {
            EditorTheme::Chrome => "Chrome".into(),
            EditorTheme::Clouds => "Clouds".into(),
            EditorTheme::CrimsonEditor => "Crimson Editor".into(),
            EditorTheme::Dawn => "Dawn".into(),
            EditorTheme::Dreamweaver => "Dreamweaver".into(),
            EditorTheme::Eclipse => "Eclipse".into(),
            EditorTheme::GitHub => "GitHub".into(),
            EditorTheme::SolarizedLight => "Solarized Light".into(),
            EditorTheme::TextMate => "TextMate".into(),
            EditorTheme::Tomorrow => "Tomorrow".into(),
            EditorTheme::XCode => "XCode".into(),
            EditorTheme::Kuroir => "Kuroir".into(),
            EditorTheme::KatzenMilch => "KatzenMilch".into(),
            EditorTheme::Ambiance => "Ambiance".into(),
            EditorTheme::Chaos => "Chaos".into(),
            EditorTheme::CloudsMidnight => "Clouds Midnight".into(),
            EditorTheme::Cobalt => "Cobalt".into(),
            EditorTheme::IdleFingers => "Idle Fingers".into(),
            EditorTheme::KrTheme => "krTheme".into(),
            EditorTheme::Merbivore => "Merbivore".into(),
            EditorTheme::MerbivoreSoft => "Merbivore Soft".into(),
            EditorTheme::MonoIndustrial => "Mono Industrial".into(),
            EditorTheme::Monokai => "Monokai".into(),
            EditorTheme::PastelOnDark => "Pastel on dark".into(),
            EditorTheme::SolarizedDark => "Solarized Dark".into(),
            EditorTheme::Terminal => "Terminal".into(),
            EditorTheme::TomorrowNight => "Tomorrow Night".into(),
            EditorTheme::TomorrowNightBlue => "Tomorrow Night Blue".into(),
            EditorTheme::TomorrowNightBright => "Tomorrow Night Bright".into(),
            EditorTheme::TomorrowNightEighties => "Tomorrow Night 80s".into(),
            EditorTheme::Twilight => "Twilight".into(),
            EditorTheme::VibrantInk => "Vibrant Ink".into(),
        }
    }

    pub fn ace_theme(&self) -> String {
        match self {
            EditorTheme::Chrome => "ace/theme/chrome".into(),
            EditorTheme::Clouds => "ace/theme/clouds".into(),
            EditorTheme::CrimsonEditor => "ace/theme/crimson_editor".into(),
            EditorTheme::Dawn => "ace/theme/dawn".into(),
            EditorTheme::Dreamweaver => "ace/theme/dreamweaver".into(),
            EditorTheme::Eclipse => "ace/theme/eclipse".into(),
            EditorTheme::GitHub => "ace/theme/github".into(),
            EditorTheme::SolarizedLight => "ace/theme/solarized_light".into(),
            EditorTheme::TextMate => "ace/theme/textmate".into(),
            EditorTheme::Tomorrow => "ace/theme/tomorrow".into(),
            EditorTheme::XCode => "ace/theme/xcode".into(),
            EditorTheme::Kuroir => "ace/theme/kuroir".into(),
            EditorTheme::KatzenMilch => "ace/theme/katzenmilch".into(),
            EditorTheme::Ambiance => "ace/theme/ambiance".into(),
            EditorTheme::Chaos => "ace/theme/chaos".into(),
            EditorTheme::CloudsMidnight => "ace/theme/clouds_midnight".into(),
            EditorTheme::Cobalt => "ace/theme/cobalt".into(),
            EditorTheme::IdleFingers => "ace/theme/idle_fingers".into(),
            EditorTheme::KrTheme => "ace/theme/kr_theme".into(),
            EditorTheme::Merbivore => "ace/theme/merbivore".into(),
            EditorTheme::MerbivoreSoft => "ace/theme/merbivore_soft".into(),
            EditorTheme::MonoIndustrial => "ace/theme/mono_industrial".into(),
            EditorTheme::Monokai => "ace/theme/monokai".into(),
            EditorTheme::PastelOnDark => "ace/theme/pastel_on_dark".into(),
            EditorTheme::SolarizedDark => "ace/theme/solarized_dark".into(),
            EditorTheme::Terminal => "ace/theme/terminal".into(),
            EditorTheme::TomorrowNight => "ace/theme/tomorrow_night".into(),
            EditorTheme::TomorrowNightBlue => "ace/theme/tomorrow_night_blue".into(),
            EditorTheme::TomorrowNightBright => "ace/theme/tomorrow_night_bright".into(),
            EditorTheme::TomorrowNightEighties => "ace/theme/tomorrow_night_eighties".into(),
            EditorTheme::Twilight => "ace/theme/twilight".into(),
            EditorTheme::VibrantInk => "ace/theme/vibrant_ink".into(),
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize, PartialEq, Default)]
#[serde(rename_all = "camelCase")]
pub enum EditorKeyboardBindings {
    #[default]
    Default,
    Vim,
    Emacs,
}

impl EditorKeyboardBindings {
    pub fn ace_keyboard_handler(&self) -> String {
        match self {
            EditorKeyboardBindings::Default => "".into(),
            EditorKeyboardBindings::Vim => "ace/keyboard/vim".into(),
            EditorKeyboardBindings::Emacs => "ace/keyboard/emacs".into(),
        }
    }

    pub fn label(&self) -> String {
        match self {
            EditorKeyboardBindings::Default => "Default".into(),
            EditorKeyboardBindings::Vim => "Vim".into(),
            EditorKeyboardBindings::Emacs => "Emacs".into(),
        }
    }
}
