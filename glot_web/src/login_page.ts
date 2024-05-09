import init, { loginPage } from "../wasm/glot";
import { Poly } from "poly";
import { defaultDebugConfig } from "poly/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const poly = new Poly(loginPage(location.href), {
    loggerConfig: defaultDebugConfig(),
  });

  poly.init();
})();
