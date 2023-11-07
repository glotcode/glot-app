import init, { snippetPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { defaultDebugConfig } from "poly/src/logger";
import { AceEditorElement } from "poly-ace-editor";

AceEditorElement.register();

(async () => {
  const snippetId = snippetIdFromUrl(location.href);
  const snippetPromise = fetchSnippet(snippetId);

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

function snippetIdFromUrl(url: string): string {
  const parts = url.split("/");
  return parts.pop() as string;
}
