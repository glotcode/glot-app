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

fn get_modifier_key(user_agent: &UserAgent) -> ModifierKey {
    match user_agent.os {
        OperatingSystem::Mac => ModifierKey::Meta,
        _ => ModifierKey::Ctrl,
    }
}
