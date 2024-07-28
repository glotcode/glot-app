use std::fmt;

use crate::util::user_agent::{OperatingSystem, UserAgent};
use poly::browser::{Key, ModifierKey};

pub enum KeyboardShortcut {
    OpenQuickSearch,
    RunCode,
}

impl KeyboardShortcut {
    pub fn key_combo(&self, user_agent: &UserAgent) -> KeyCombo {
        let modifier = get_modifier_key(user_agent);

        match self {
            KeyboardShortcut::OpenQuickSearch => KeyCombo {
                key: Key::Key("KeyK".to_string()),
                modifier,
            },

            KeyboardShortcut::RunCode => KeyCombo {
                key: Key::Enter,
                modifier,
            },
        }
    }
}

pub struct KeyCombo {
    pub key: Key,
    pub modifier: ModifierKey,
}

impl fmt::Display for KeyCombo {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let key_str = self.key.to_string();
        let key = key_str.trim_start_matches("Key").replace("enter", "Enter");

        match self.modifier {
            ModifierKey::None => write!(f, "{}", key),
            ModifierKey::Ctrl => write!(f, "Ctrl+{}", key),
            ModifierKey::Meta => write!(f, "⌘+{}", key),
            ModifierKey::Multiple(_) => write!(f, ""),
        }
    }
}

fn get_modifier_key(user_agent: &UserAgent) -> ModifierKey {
    match user_agent.os {
        OperatingSystem::Mac => ModifierKey::Meta,
        _ => ModifierKey::Ctrl,
    }
}
