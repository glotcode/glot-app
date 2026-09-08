//// The browser environment the editor page starts in.
////
//// Stored editor settings keep their existing format; the platform flag is
//// read once at start-up because the default keymap is platform-aware, exactly
//// as CodeMirror's was.

import glot_frontend/public/editor/settings

pub type Environment {
  Environment(settings: settings.EditorSettings, mac: Bool)
}

pub fn defaults() -> Environment {
  Environment(settings: settings.defaults(), mac: False)
}
