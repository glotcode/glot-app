import init, { snippetPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { AceEditorElement } from "poly-ace-editor";
import { createSnippet, getSnippet, run } from "./api";

AceEditorElement.register();

(async () => {
  const snippetPromise = getSnippetMaybe();

  await init("/wasm/glot_bg.wasm");
  const snippet = await snippetPromise;

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(snippetPage(snippet, windowSize, location.href), {
    //loggerConfig: defaultDebugConfig(),
  });

  poly.onAppEffect(async (msg) => {
    switch (msg.type) {
      case "run":
        const runResponse = await run(msg.config);
        poly.sendMessage("GotRunResponse", runResponse);
        break;
      case "createSnippet":
        const snippet = await createSnippet(msg.config);
        poly.sendMessage("GotCreateSnippetResponse", snippet);
        break;
    }
  });

  poly.init();
})();

function getSnippetMaybe(): Promise<unknown> {
  const snippetId = snippetIdFromPath(location.pathname);
  if (!snippetId) {
    return Promise.resolve(null);
  }

  return getSnippet(snippetId);
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
