import init from "../wasm/glot.js";
import { snippetPage } from "../wasm/glot";
import { BrowserWindow, Polyester } from "polyester";
import { defaultDebugConfig } from "polyester/src/logger";
import { AceEditorElement } from "poly-ace-editor";

// poly-ace-editor is imported to make the custom element available
// Assign to variable to prevent dead code elimination
const _AceEditorElement = AceEditorElement;

(async () => {
  await init("/wasm/glot_bg.wasm");

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const polyester = new Polyester(snippetPage(windowSize, location.href), {
    loggerConfig: defaultDebugConfig(),
  });

  polyester.init();
})();
