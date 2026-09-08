// Entry point for the browser integration tests. It is not part of any
// production bundle: `vite build` never sees it, and it lives beside the
// harness page it serves.
import { main } from "../build/dev/javascript/glot_frontend/support/browser_harness.mjs";
import { applyThemePreference } from "./custom_elements/glot-theme-picker";

applyThemePreference();

const bindings = new URLSearchParams(window.location.search).get("bindings");
main(bindings ?? "default");
