import init from "../wasm/glot.js";
import { homePage } from "../wasm/glot";
import { Polyester } from "polyester";
import { defaultDebugConfig } from "polyester/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const polyester = new Polyester(homePage(), {
    loggerConfig: defaultDebugConfig(),
  });

  polyester.init();
})();
