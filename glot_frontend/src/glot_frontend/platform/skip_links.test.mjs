import assert from "node:assert/strict";
import test from "node:test";
import { handleSkipLinkClick } from "./skip_links.mjs";

function fixture({ href = "https://glot.io/javascript#main-content" } = {}) {
  const calls = [];
  const destination = {
    focus(options) {
      calls.push(["focus", options]);
    },
    scrollIntoView(options) {
      calls.push(["scroll", options]);
    },
  };
  const link = { href };
  const event = {
    target: {
      nodeType: 1,
      closest(selector) {
        assert.equal(selector, "a.skip-link[href]");
        return link;
      },
    },
    preventDefault() {
      calls.push(["preventDefault"]);
    },
    stopImmediatePropagation() {
      calls.push(["stopImmediatePropagation"]);
    },
  };
  const browserWindow = {
    location: { href: "https://glot.io/javascript" },
    history: {
      pushState(state, title, url) {
        calls.push(["pushState", state, title, url]);
      },
    },
  };
  const root = {
    getElementById(id) {
      calls.push(["getElementById", id]);
      return destination;
    },
  };

  return { browserWindow, calls, event, root };
}

test("skip links focus and scroll without reaching the SPA router", () => {
  const { browserWindow, calls, event, root } = fixture();

  assert.equal(handleSkipLinkClick(event, browserWindow, root), true);
  assert.deepEqual(calls, [
    ["getElementById", "main-content"],
    ["preventDefault"],
    ["stopImmediatePropagation"],
    ["pushState", {}, "", "/javascript#main-content"],
    ["focus", { preventScroll: true }],
    ["scroll", { block: "start" }],
  ]);
});

test("cross-document links are left to normal navigation", () => {
  const { browserWindow, calls, event, root } = fixture({
    href: "https://glot.io/python#main-content",
  });

  assert.equal(handleSkipLinkClick(event, browserWindow, root), false);
  assert.deepEqual(calls, []);
});
