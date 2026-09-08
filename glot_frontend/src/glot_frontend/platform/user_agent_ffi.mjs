// Platform detection for the platform-aware half of the default keymap.
//
// Both the modern and the legacy source are consulted, because tooling that
// overrides one of them (browser automation, "request desktop site") otherwise
// makes a Mac look like a PC and moves every `Mod` binding onto the wrong key.
export function isMac() {
  const navigator = globalThis.navigator;
  if (!navigator) return false;

  const platforms = [navigator.userAgentData?.platform, navigator.platform]
    .filter(Boolean)
    .join(" ");

  return /mac|iphone|ipad|ipod/i.test(platforms);
}
