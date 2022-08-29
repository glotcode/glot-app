import init from "../wasm/glot.js";
import { snippetPage } from "../wasm/glot";
import { Polyester } from "polyester";
import { defaultDebugConfig } from "polyester/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const polyester = new Polyester(snippetPage(), {
    loggerConfig: defaultDebugConfig(),
  });

  polyester.init();
})();
