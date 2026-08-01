function clickedElement(target) {
  if (target?.nodeType === 1) return target;
  return target?.parentElement ?? null;
}

export function handleSkipLinkClick(event, browserWindow, root) {
  const link = clickedElement(event.target)?.closest?.("a.skip-link[href]");
  if (!link) return false;

  const currentUrl = new URL(browserWindow.location.href);
  const destinationUrl = new URL(link.href, currentUrl);
  const isSameDocument =
    destinationUrl.origin === currentUrl.origin &&
    destinationUrl.pathname === currentUrl.pathname &&
    destinationUrl.search === currentUrl.search;

  if (!isSameDocument || destinationUrl.hash.length < 2) return false;

  let targetId;
  try {
    targetId = decodeURIComponent(destinationUrl.hash.slice(1));
  } catch {
    return false;
  }

  const destination = root.getElementById(targetId);
  if (!destination) return false;

  event.preventDefault();
  event.stopImmediatePropagation();

  if (currentUrl.hash !== destinationUrl.hash) {
    browserWindow.history.pushState(
      {},
      "",
      destinationUrl.pathname + destinationUrl.search + destinationUrl.hash,
    );
  }

  destination.focus({ preventScroll: true });
  destination.scrollIntoView({ block: "start" });
  return true;
}

export function initializeSkipLinks(browserWindow = window, root = document) {
  root.addEventListener(
    "click",
    (event) => {
      handleSkipLinkClick(event, browserWindow, root);
    },
    true,
  );
}
