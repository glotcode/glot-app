import init, { snippetPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { defaultDebugConfig } from "poly/src/logger";
import { AceEditorElement } from "poly-ace-editor";

AceEditorElement.register();

(async () => {
  const snippetPromise = getSnippet();

  await init("/wasm/glot_bg.wasm");
  const snippet = await snippetPromise;

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(snippetPage(snippet, windowSize, location.href), {
    //loggerConfig: defaultDebugConfig(),
  });

  poly.onAppEffect((msg) => {
    switch (msg.type) {
      case "run":
        run(poly, msg.config);
        break;
      case "createSnippet":
        createSnippet(poly, msg.config);
        break;
    }
  });

  poly.init();
})();

async function run(poly: Poly, data: any) {
  const response = await fetch("/api/run", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  const runResponse = await response.json();

  poly.sendMessage("GotRunResponse", runResponse);
}

async function createSnippet(poly: Poly, data: any) {
  const response = await fetch("/api/snippets", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  const snippet = await response.json();

  poly.sendMessage("GotCreateSnippetResponse", snippet);
}

async function fetchSnippet(snippetId: string): Promise<unknown> {
  const url = `/api/snippets/${snippetId}`;
  const response = await fetch(url);
  return response.json();
}

function getSnippet(): Promise<unknown> {
  const snippetId = snippetIdFromPath(location.pathname);
  if (snippetId) {
    return fetchSnippet(snippetId);
  }

  return Promise.resolve(null);
}

function snippetIdFromPath(path: string): string | null {
  const parts = path.slice(1).split("/");

  if (parts.length != 2) {
    return null;
  }

  if (parts[0] !== "snippets") {
    return null;
  }

  return parts.pop() as string;
}
