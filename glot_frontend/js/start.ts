import { initializeTheme } from "./custom_elements/glot-theme-picker";
import { initializePrivacyElements } from "./custom_elements/glot-privacy";
import { initializeSkipLinks } from "../src/glot_frontend/platform/skip_links.mjs";

let codeMirrorImport: Promise<unknown> | null = null;

function loadCodeMirror() {
  if (customElements.get("glot-codemirror")) {
    return Promise.resolve();
  }

  codeMirrorImport ??= import("./custom_elements/glot-codemirror");
  return codeMirrorImport;
}

function loadCodeMirrorIfPresent(node: Node) {
  if (node instanceof Element) {
    if (node.matches("glot-codemirror") || node.querySelector("glot-codemirror")) {
      void loadCodeMirror();
    }

    return;
  }

  if (node instanceof Document && node.querySelector("glot-codemirror")) {
    void loadCodeMirror();
  }
}

export function start(main: () => unknown) {
  initializeTheme();
  initializeSkipLinks();

  const codeMirrorObserver = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        loadCodeMirrorIfPresent(node);
      }
    }
  });

  codeMirrorObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });

  main();
  initializePrivacyElements();
  loadCodeMirrorIfPresent(document);
}
