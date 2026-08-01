const navigationEvent = "glot-spa-navigation";

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
  browserWindow.history.pushState({}, "", destination.href);
  dispatch(destination.href);
  return true;
}

export function observe(
  dispatch,
  browserWindow = window,
  root = document,
) {
  browserWindow.history.scrollRestoration = "manual";
  root.addEventListener("click", (event) => {
    handleClick(event, dispatch, browserWindow);
  });
  browserWindow.addEventListener("popstate", () => {
    dispatch(browserWindow.location.href);
  });
  browserWindow.addEventListener(navigationEvent, (event) => {
    dispatch(event.detail);
  });
}

function navigateHistory(method, path, browserWindow = window) {
  browserWindow.history[method]({}, "", path);
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

export function commit(browserWindow = window, root = document) {
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
    const focusTarget = destination ?? root.getElementById("main-content");

    if (destination) {
      destination.scrollIntoView({ block: "start" });
    } else {
      browserWindow.scrollTo(0, 0);
    }

    focusTarget?.focus?.({ preventScroll: true });
  });
}
