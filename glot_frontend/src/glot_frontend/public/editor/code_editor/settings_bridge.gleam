//// Translates the stored editor settings into the editor's own binding mode.
////
//// The stored values are part of an existing persisted format, so they stay
//// exactly as they were; this module keeps that vocabulary out of the editor
//// internals.

import glot_frontend/public/editor/settings

pub type BindingMode {
  Plain
  EmacsLike
  VimLike
}

pub fn from_settings(bindings: settings.KeyboardBindings) -> BindingMode {
  case bindings {
    settings.DefaultBindings -> Plain
    settings.EmacsBindings -> EmacsLike
    settings.VimBindings -> VimLike
  }
}

pub fn to_settings(mode: BindingMode) -> settings.KeyboardBindings {
  case mode {
    Plain -> settings.DefaultBindings
    EmacsLike -> settings.EmacsBindings
    VimLike -> settings.VimBindings
  }
}
