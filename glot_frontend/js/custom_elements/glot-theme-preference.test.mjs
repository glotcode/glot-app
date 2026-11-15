import assert from "node:assert/strict";
import test from "node:test";

import {
  readThemeCookie,
  serializeThemeCookie,
} from "./glot-theme-preference.mjs";

test("reads light, white and dark preferences from the theme cookie", () => {
  assert.equal(readThemeCookie("session=abc; glot_theme=light"), "light");
  assert.equal(readThemeCookie("glot_theme=white"), "white");
  assert.equal(readThemeCookie("glot_theme=dark; session=abc"), "dark");
});

test("uses the system preference for missing or invalid cookies", () => {
  assert.equal(readThemeCookie("session=abc"), "system");
  assert.equal(readThemeCookie("glot_theme=sepia"), "system");
  assert.equal(readThemeCookie("glot_theme=%invalid"), "system");
});

test("serializes persistent theme cookies", () => {
  assert.equal(
    serializeThemeCookie("dark", true),
    "glot_theme=dark; Path=/; Max-Age=31536000; SameSite=Lax; Secure",
  );
  assert.equal(
    serializeThemeCookie("light", false),
    "glot_theme=light; Path=/; Max-Age=31536000; SameSite=Lax",
  );
});

test("system preference expires the theme cookie", () => {
  assert.equal(
    serializeThemeCookie("system", false),
    "glot_theme=; Path=/; Max-Age=0; SameSite=Lax",
  );
});
