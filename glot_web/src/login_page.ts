import init, { loginPage } from "../wasm/glot";
import { BrowserWindow, Poly } from "poly";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const poly = new Poly(loginPage(location.href, windowSize), {
    //loggerConfig: defaultDebugConfig(),
  });

  poly.init();
})();
