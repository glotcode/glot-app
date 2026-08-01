const navigationEvent = "glot-spa-navigation";
const entryStateKey = "__glotSpaNavigationEntry";
const entryStateVersion = 1;

const scrollPositions = new Map();
let scrollCaptureScheduled = false;

function newEntryId(browserWindow) {
  return browserWindow.crypto.randomUUID();
}

function newEntry(browserWindow, position) {
  return {
    version: entryStateVersion,
    id: newEntryId(browserWindow),
    ...position,
  };
}

function stateWithEntry(state, entry) {
  const preservedState =
    state && typeof state === "object" && !Array.isArray(state) ? state : {};
  return { ...preservedState, [entryStateKey]: entry };
}

function entryFromState(state) {
  const entry = state?.[entryStateKey];
  return entry?.version === entryStateVersion &&
    typeof entry?.id === "string" &&
    Number.isFinite(entry?.x) &&
    Number.isFinite(entry?.y)
    ? entry
    : null;
}

function currentScroll(browserWindow) {
  return {
    x: browserWindow.scrollX ?? browserWindow.pageXOffset ?? 0,
    y: browserWindow.scrollY ?? browserWindow.pageYOffset ?? 0,
  };
}

function ensureCurrentEntry(browserWindow) {
  const existing = entryFromState(browserWindow.history.state);
  if (existing) {
    if (!scrollPositions.has(existing.id)) {
      scrollPositions.set(existing.id, { x: existing.x, y: existing.y });
    }
    return existing;
  }

  const position = currentScroll(browserWindow);
  const entry = newEntry(browserWindow, position);
  browserWindow.history.replaceState(
    stateWithEntry(browserWindow.history.state, entry),
    "",
    browserWindow.location.href,
  );
  scrollPositions.set(entry.id, position);
  return entry;
}

function captureCurrentScroll(browserWindow, persist = false) {
  const entry = ensureCurrentEntry(browserWindow);
  const position = currentScroll(browserWindow);
  scrollPositions.set(entry.id, position);

  if (persist && (entry.x !== position.x || entry.y !== position.y)) {
    browserWindow.history.replaceState(
      stateWithEntry(browserWindow.history.state, {
        version: entryStateVersion,
        id: entry.id,
        ...position,
      }),
      "",
      browserWindow.location.href,
    );
  }
}

function scheduleScrollCapture(browserWindow) {
  captureCurrentScroll(browserWindow);
  if (scrollCaptureScheduled) return;

  scrollCaptureScheduled = true;
  browserWindow.requestAnimationFrame(() => {
    scrollCaptureScheduled = false;
    const currentEntry = ensureCurrentEntry(browserWindow);

    const position = scrollPositions.get(currentEntry.id);
    if (!position) return;
    browserWindow.history.replaceState(
      stateWithEntry(browserWindow.history.state, {
        version: entryStateVersion,
        id: currentEntry.id,
        ...position,
      }),
      "",
      browserWindow.location.href,
    );
  });
}

function createEntry(browserWindow, method, destination) {
  captureCurrentScroll(browserWindow, true);
  const entry = newEntry(browserWindow, { x: 0, y: 0 });
  browserWindow.history[method](stateWithEntry({}, entry), "", destination);
  scrollPositions.set(entry.id, { x: 0, y: 0 });
  return entry;
}

function dispatchReset(dispatch, location) {
  dispatch(location, false, 0, 0);
}

function dispatchRestoration(dispatch, browserWindow) {
  const entry = ensureCurrentEntry(browserWindow);
  const position = scrollPositions.get(entry.id) ?? { x: entry.x, y: entry.y };
  dispatch(browserWindow.location.href, true, position.x, position.y);
}

export function initialLocation(browserWindow = globalThis?.window) {
  return browserWindow?.location?.href ?? "";
}

function clickedLink(target) {
  const element = target?.nodeType === 1 ? target : target?.parentElement;
  return element?.closest?.("a[href]") ?? null;
}

function internalDestination(link, browserWindow) {
  try {
    const destination = new URL(link.href, browserWindow.location.href);
    return destination.origin === browserWindow.location.origin
      ? destination
      : null;
  } catch {
    return null;
  }
}

function isSameDocumentFragment(destination, browserWindow) {
  const current = new URL(browserWindow.location.href);
  return (
    destination.pathname === current.pathname &&
    destination.search === current.search &&
    destination.hash.length > 0
  );
}

export function handleClick(event, dispatch, browserWindow = window) {
  if (event.defaultPrevented || event.button !== 0) return false;
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
    return false;
  }

  const link = clickedLink(event.target);
  if (!link || link.hasAttribute("download")) return false;
  if (link.target && link.target !== "_self") return false;

  const destination = internalDestination(link, browserWindow);
  if (!destination || isSameDocumentFragment(destination, browserWindow)) {
    return false;
  }

  event.preventDefault();
  createEntry(browserWindow, "pushState", destination.href);
  dispatchReset(dispatch, destination.href);
  return true;
}

export function observe(
  dispatch,
  browserWindow = window,
  root = document,
) {
  browserWindow.history.scrollRestoration = "manual";
  const initialEntry = ensureCurrentEntry(browserWindow);
  scrollPositions.set(initialEntry.id, currentScroll(browserWindow));

  root.addEventListener("click", (event) => {
    handleClick(event, dispatch, browserWindow);
  });
  browserWindow.addEventListener("scroll", () => {
    scheduleScrollCapture(browserWindow);
  }, { passive: true });
  browserWindow.addEventListener("popstate", () => {
    dispatchRestoration(dispatch, browserWindow);
  });
  browserWindow.addEventListener(navigationEvent, (event) => {
    dispatchReset(dispatch, event.detail);
  });
}

function navigateHistory(method, path, browserWindow = window) {
  createEntry(browserWindow, method, path);
  browserWindow.dispatchEvent(
    new browserWindow.CustomEvent(navigationEvent, {
      detail: browserWindow.location.href,
    }),
  );
}

export function push(path, browserWindow = window) {
  navigateHistory("pushState", path, browserWindow);
}

export function replace(path, browserWindow = window) {
  navigateHistory("replaceState", path, browserWindow);
}

export function commit(
  restore = false,
  x = 0,
  y = 0,
  browserWindow = window,
  root = document,
) {
  browserWindow.requestAnimationFrame(() => {
    const hash = browserWindow.location.hash;
    let destination = null;
    try {
      destination = hash
        ? root.getElementById(decodeURIComponent(hash.slice(1)))
        : null;
    } catch {
      destination = null;
    }
    const focusTarget = restore
      ? root.getElementById("main-content")
      : destination ?? root.getElementById("main-content");

    if (restore) {
      browserWindow.scrollTo(x, y);
    } else if (destination) {
      destination.scrollIntoView({ block: "start" });
    } else {
      browserWindow.scrollTo(0, 0);
    }

    focusTarget?.focus?.({ preventScroll: true });
  });
}
