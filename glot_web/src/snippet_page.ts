import init, { snippetPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { AceEditorElement } from "poly-ace-editor";
import { run } from "./api";

AceEditorElement.register();

(async () => {
  await init("/wasm/glot_bg.wasm");
  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(snippetPage(windowSize, location.href), {
    //loggerConfig: defaultDebugConfig(),
  });

  poly.onAppEffect(async (msg) => {
    switch (msg.type) {
      case "run":
        const runResponse = await run(msg.config);
        poly.sendMessage("GotRunResponse", runResponse);
        break;
    }
  });

  poly.init();
})();