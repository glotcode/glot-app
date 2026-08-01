import assert from "node:assert/strict";
import test from "node:test";
import {
  commit,
  handleClick,
  initialLocation,
  push,
  replace,
} from "./spa_navigation_ffi.mjs";

test("initial location is read safely from the browser boundary", () => {
  assert.equal(
    initialLocation({ location: { href: "https://glot.io/snippets" } }),
    "https://glot.io/snippets",
  );
  assert.equal(initialLocation(undefined), "");
});

function clickFixture(href = "https://glot.io/snippets") {
  const calls = [];
  const link = {
    href,
    target: "",
    hasAttribute(name) {
      assert.equal(name, "download");
      return false;
    },
  };
  const event = {
    defaultPrevented: false,
    button: 0,
    metaKey: false,
    ctrlKey: false,
    shiftKey: false,
    altKey: false,
    target: {
      nodeType: 1,
      closest(selector) {
        assert.equal(selector, "a[href]");
        return link;
      },
    },
    preventDefault() {
      calls.push("preventDefault");
    },
  };
  const browserWindow = {
    location: {
      href: "https://glot.io/",
      origin: "https://glot.io",
    },
    history: {
      pushState(state, title, destination) {
        calls.push(["pushState", state, title, destination]);
      },
    },
  };

  return { browserWindow, calls, event };
}

test("internal clicks update history and dispatch without scrolling", () => {
  const { browserWindow, calls, event } = clickFixture();
  const dispatched = [];

  assert.equal(
    handleClick(event, (location) => dispatched.push(location), browserWindow),
    true,
  );
  assert.deepEqual(calls, [
    "preventDefault",
    ["pushState", {}, "", "https://glot.io/snippets"],
  ]);
  assert.deepEqual(dispatched, ["https://glot.io/snippets"]);
});

test("modified, external, and same-document fragment clicks stay native", () => {
  const modified = clickFixture();
  modified.event.metaKey = true;
  assert.equal(handleClick(modified.event, () => {}, modified.browserWindow), false);
  assert.deepEqual(modified.calls, []);

  const external = clickFixture("https://example.com/snippets");
  assert.equal(handleClick(external.event, () => {}, external.browserWindow), false);
  assert.deepEqual(external.calls, []);

  const fragment = clickFixture("https://glot.io/#main-content");
  assert.equal(handleClick(fragment.event, () => {}, fragment.browserWindow), false);
  assert.deepEqual(fragment.calls, []);
});

test("programmatic push and replace notify the route observer", () => {
  const calls = [];
  class FakeCustomEvent {
    constructor(type, options) {
      this.type = type;
      this.detail = options.detail;
    }
  }
  const browserWindow = {
    CustomEvent: FakeCustomEvent,
    location: { href: "https://glot.io/contact" },
    history: {
      pushState(state, title, path) {
        calls.push(["pushState", state, title, path]);
      },
      replaceState(state, title, path) {
        calls.push(["replaceState", state, title, path]);
      },
    },
    dispatchEvent(event) {
      calls.push(["dispatch", event.type, event.detail]);
    },
  };

  push("/contact", browserWindow);
  replace("/", browserWindow);

  assert.deepEqual(calls, [
    ["pushState", {}, "", "/contact"],
    ["dispatch", "glot-spa-navigation", "https://glot.io/contact"],
    ["replaceState", {}, "", "/"],
    ["dispatch", "glot-spa-navigation", "https://glot.io/contact"],
  ]);
});

test("commit scrolls and focuses only on the next animation frame", () => {
  const calls = [];
  let frame;
  const main = {
    focus(options) {
      calls.push(["focus", options]);
    },
  };
  const browserWindow = {
    location: { hash: "" },
    requestAnimationFrame(callback) {
      frame = callback;
    },
    scrollTo(x, y) {
      calls.push(["scrollTo", x, y]);
    },
  };
  const root = {
    getElementById(id) {
      assert.equal(id, "main-content");
      return main;
    },
  };

  commit(browserWindow, root);
  assert.deepEqual(calls, []);
  frame();
  assert.deepEqual(calls, [
    ["scrollTo", 0, 0],
    ["focus", { preventScroll: true }],
  ]);
});
