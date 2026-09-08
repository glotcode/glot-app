//// Platform detection, used only to choose between the macOS and the
//// Windows/Linux variants of the default keymap.

@external(javascript, "./user_agent_ffi.mjs", "isMac")
pub fn is_mac() -> Bool
