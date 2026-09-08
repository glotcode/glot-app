import { initializeTheme } from "./custom_elements/glot-theme-picker";
import { initializePrivacyElements } from "./custom_elements/glot-privacy";
import { initializeSkipLinks } from "../src/glot_frontend/platform/skip_links.mjs";

export function start(main: () => unknown) {
  initializeTheme();
  initializeSkipLinks();

  main();
  initializePrivacyElements();
}
