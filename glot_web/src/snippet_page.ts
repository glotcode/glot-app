import init, { snippetPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { defaultDebugConfig } from "poly/src/logger";
import { AceEditorElement } from "poly-ace-editor";

AceEditorElement.register();

(async () => {
  await init("/wasm/glot_bg.wasm");

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(snippetPage(windowSize, location.href), {
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
