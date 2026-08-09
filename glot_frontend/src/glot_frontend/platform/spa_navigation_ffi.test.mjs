import assert from "node:assert/strict";
import test from "node:test";
import {
  commit,
  handleClick,
  initialLocation,
  observe,
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

let nextFixtureUuid = 0;

function fixtureUuid() {
  nextFixtureUuid += 1;
  return `00000000-0000-4000-8000-${String(nextFixtureUuid).padStart(12, "0")}`;
}

function browserFixture({
  href = "https://glot.io/",
  randomUUID = fixtureUuid,
  pushStateError = null,
  scrollX = 0,
  scrollY = 0,
  state = { preserved: true },
} = {}) {
  const calls = [];
  const listeners = new Map();
  const frames = [];
  const location = {};

  function setLocation(nextHref) {
    const url = new URL(nextHref, location.href ?? href);
    location.href = url.href;
    location.origin = url.origin;
    location.hash = url.hash;
  }

  setLocation(href);

  class FakeCustomEvent {
    constructor(type, options) {
      this.type = type;
      this.detail = options.detail;
    }
  }

  const browserWindow = {
    CustomEvent: FakeCustomEvent,
    crypto: { randomUUID },
    location,
    scrollX,
    scrollY,
    requestAnimationFrame(callback) {
      frames.push(callback);
    },
    history: {
      state,
      scrollRestoration: "auto",
      pushState(nextState, title, destination) {
        if (pushStateError) throw pushStateError;
        calls.push(["pushState", nextState, title, destination]);
        this.state = nextState;
        setLocation(destination);
      },
      replaceState(nextState, title, destination) {
        calls.push(["replaceState", nextState, title, destination]);
        this.state = nextState;
        setLocation(destination);
      },
    },
    addEventListener(type, listener, options) {
      calls.push(["listen", type, options]);
      listeners.set(type, listener);
    },
    dispatchEvent(event) {
      calls.push(["dispatch", event.type, event.detail]);
      listeners.get(event.type)?.(event);
    },
  };
  const root = {
    addEventListener(type, listener) {
      calls.push(["root-listen", type]);
      listeners.set(`root:${type}`, listener);
    },
  };

  return {
    browserWindow,
    calls,
    flushFrames() {
      while (frames.length > 0) frames.shift()();
    },
    listeners,
    root,
    setLocation,
  };
}

function clickFixture(href = "https://glot.io/snippets", browser = browserFixture()) {
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
      browser.calls.push("preventDefault");
    },
  };

  return { ...browser, event };
}

test("internal clicks create a fresh keyed history entry", () => {
  const fixture = clickFixture();
  const dispatched = [];

  assert.equal(
    handleClick(
      fixture.event,
      (...navigation) => dispatched.push(navigation),
      fixture.browserWindow,
    ),
    true,
  );

  const historyCalls = fixture.calls.filter(
    (call) => Array.isArray(call) && ["replaceState", "pushState"].includes(call[0]),
  );
  assert.equal(historyCalls.length, 2);
  assert.equal(historyCalls[0][1].preserved, true);
  assert.equal(
    typeof historyCalls[0][1].__glotSpaNavigationEntry.id,
    "string",
  );
  assert.equal(historyCalls[0][1].__glotSpaNavigationEntry.version, 1);
  assert.equal(
    typeof historyCalls[1][1].__glotSpaNavigationEntry.id,
    "string",
  );
  assert.equal(historyCalls[1][1].__glotSpaNavigationEntry.version, 1);
  assert.notEqual(
    historyCalls[0][1].__glotSpaNavigationEntry.id,
    historyCalls[1][1].__glotSpaNavigationEntry.id,
  );
  assert.equal(historyCalls[1][3], "https://glot.io/snippets");
  assert.deepEqual(dispatched, [["https://glot.io/snippets", false, 0, 0]]);
});

test("failed history interception falls back to native link navigation", () => {
  const fixture = clickFixture(
    "https://glot.io/snippets?after=next-page",
    browserFixture({ pushStateError: new Error("history rate limited") }),
  );
  const dispatched = [];

  assert.equal(
    handleClick(
      fixture.event,
      (...navigation) => dispatched.push(navigation),
      fixture.browserWindow,
    ),
    false,
  );

  assert.equal(fixture.calls.includes("preventDefault"), false);
  assert.deepEqual(dispatched, []);
});

test("entry identity remains unique when navigation is reinitialized", () => {
  const first = browserFixture({
    randomUUID: () => "11111111-1111-4111-8111-111111111111",
  });
  observe(() => {}, first.browserWindow, first.root);
  const firstId = first.browserWindow.history.state.__glotSpaNavigationEntry.id;

  const reloaded = browserFixture({
    href: first.browserWindow.location.href,
    state: first.browserWindow.history.state,
    randomUUID: () => "22222222-2222-4222-8222-222222222222",
  });
  observe(() => {}, reloaded.browserWindow, reloaded.root);
  push("/contact", reloaded.browserWindow);
  const nextEntry =
    reloaded.browserWindow.history.state.__glotSpaNavigationEntry;

  assert.equal(firstId, "11111111-1111-4111-8111-111111111111");
  assert.equal(nextEntry.id, "22222222-2222-4222-8222-222222222222");
  assert.notEqual(nextEntry.id, firstId);
  assert.equal(nextEntry.version, 1);
});

test("unknown private history state is replaced from the current position", () => {
  const fixture = browserFixture({
    randomUUID: () => "33333333-3333-4333-8333-333333333333",
    scrollX: 7,
    scrollY: 360,
    state: {
      preserved: "foreign-state",
      __glotSpaNavigationEntry: {
        version: 99,
        id: "unsupported",
        x: 1,
        y: 2,
      },
    },
  });

  observe(() => {}, fixture.browserWindow, fixture.root);

  assert.deepEqual(
    fixture.browserWindow.history.state.__glotSpaNavigationEntry,
    {
      version: 1,
      id: "33333333-3333-4333-8333-333333333333",
      x: 7,
      y: 360,
    },
  );
  assert.equal(fixture.browserWindow.history.state.preserved, "foreign-state");
});

test("modified, external, and same-document fragment clicks stay native", () => {
  const modified = clickFixture();
  modified.event.metaKey = true;
  assert.equal(
    handleClick(modified.event, () => {}, modified.browserWindow),
    false,
  );
  assert.deepEqual(modified.calls, []);

  const external = clickFixture("https://example.com/snippets");
  assert.equal(
    handleClick(external.event, () => {}, external.browserWindow),
    false,
  );
  assert.deepEqual(external.calls, []);

  const fragment = clickFixture("https://glot.io/#main-content");
  assert.equal(
    handleClick(fragment.event, () => {}, fragment.browserWindow),
    false,
  );
  assert.deepEqual(fragment.calls, []);
});

test("history traversal restores the scroll position of its entry", () => {
  const fixture = browserFixture({
    href: "https://glot.io/snippets",
    scrollX: 12,
    scrollY: 640,
  });
  const observed = [];
  observe(
    (...navigation) => observed.push(navigation),
    fixture.browserWindow,
    fixture.root,
  );
  const listEntryState = fixture.browserWindow.history.state;

  const click = clickFixture("https://glot.io/snippet/example", fixture);
  handleClick(
    click.event,
    (...navigation) => observed.push(navigation),
    fixture.browserWindow,
  );
  assert.deepEqual(observed, [
    ["https://glot.io/snippet/example", false, 0, 0],
  ]);

  fixture.browserWindow.scrollX = 0;
  fixture.browserWindow.scrollY = 120;
  fixture.listeners.get("scroll")();
  fixture.flushFrames();

  fixture.browserWindow.history.state = listEntryState;
  fixture.setLocation("https://glot.io/snippets");
  fixture.listeners.get("popstate")();

  assert.deepEqual(observed[1], [
    "https://glot.io/snippets",
    true,
    12,
    640,
  ]);
  assert.equal(fixture.browserWindow.history.scrollRestoration, "manual");
});

test("scroll capture does not continuously mutate browser history", () => {
  const fixture = browserFixture({ href: "https://glot.io/snippets" });
  observe(() => {}, fixture.browserWindow, fixture.root);
  const initialWrites = fixture.calls.filter(
    (call) => Array.isArray(call) && call[0] === "replaceState",
  ).length;

  fixture.browserWindow.scrollY = 100;
  fixture.listeners.get("scroll")();
  fixture.browserWindow.scrollY = 200;
  fixture.listeners.get("scroll")();
  fixture.flushFrames();

  const writesAfterScrolling = fixture.calls.filter(
    (call) => Array.isArray(call) && call[0] === "replaceState",
  ).length;
  assert.equal(writesAfterScrolling, initialWrites);
});

test("programmatic push and replace notify with fresh presentation", () => {
  const fixture = browserFixture({ href: "https://glot.io/snippets" });
  const observed = [];
  observe(
    (...navigation) => observed.push(navigation),
    fixture.browserWindow,
    fixture.root,
  );

  push("/contact", fixture.browserWindow);
  replace("/", fixture.browserWindow);

  assert.deepEqual(observed, [
    ["https://glot.io/contact", false, 0, 0],
    ["https://glot.io/", false, 0, 0],
  ]);
});

function commitFixture(hash = "") {
  const calls = [];
  let frame;
  const main = {
    focus(options) {
      calls.push(["focus-main", options]);
    },
  };
  const destination = {
    focus(options) {
      calls.push(["focus-destination", options]);
    },
    scrollIntoView(options) {
      calls.push(["scroll-destination", options]);
    },
  };
  const browserWindow = {
    location: { hash },
    requestAnimationFrame(callback) {
      frame = callback;
    },
    scrollTo(x, y) {
      calls.push(["scrollTo", x, y]);
    },
  };
  const root = {
    getElementById(id) {
      return id === "main-content" ? main : destination;
    },
  };
  return { browserWindow, calls, destination, frame: () => frame(), root };
}

test("fresh commits reset presentation only after the next frame", () => {
  const fixture = commitFixture();
  commit(false, 0, 0, fixture.browserWindow, fixture.root);
  assert.deepEqual(fixture.calls, []);
  fixture.frame();
  assert.deepEqual(fixture.calls, [
    ["scrollTo", 0, 0],
    ["focus-main", { preventScroll: true }],
  ]);
});

test("traversal commits restore exact scroll without reapplying a fragment", () => {
  const fixture = commitFixture("#section");
  commit(true, 24, 880, fixture.browserWindow, fixture.root);
  fixture.frame();
  assert.deepEqual(fixture.calls, [
    ["scrollTo", 24, 880],
    ["focus-main", { preventScroll: true }],
  ]);
});
