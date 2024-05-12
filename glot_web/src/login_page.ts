import init, { loginPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";
import { sendMagicLink } from "./api";
import { defaultDebugConfig } from "poly/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(loginPage(location.href, windowSize), {
    loggerConfig: defaultDebugConfig(),
  });

  poly.onAppEffect(async (msg) => {
    switch (msg.type) {
      case "sendMagicLink":
        await sendMagicLink(msg.config);
        poly.sendMessage("MagicLinkSent", true);
        break;
    }
  });

  poly.init();
})();
