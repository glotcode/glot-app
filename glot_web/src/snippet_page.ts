import init, { snippetPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { defaultDebugConfig } from "poly/src/logger";
import { AceEditorElement } from "poly-ace-editor";

// poly-ace-editor is imported to make the custom element available
// Assign to variable to prevent dead code elimination
AceEditorElement.register();

(async () => {
  await init("/wasm/glot_bg.wasm");

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(snippetPage(windowSize, location.href), {
    //loggerConfig: defaultDebugConfig(),
  });

  poly.init();
})();
