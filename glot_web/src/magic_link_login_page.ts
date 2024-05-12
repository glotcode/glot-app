import init, { magicLinkLoginPage } from "../wasm/glot";
import { Poly } from "poly";
import { defaultDebugConfig } from "poly/src/logger";
import { login } from "./api";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const poly = new Poly(magicLinkLoginPage(location.href), {
    loggerConfig: defaultDebugConfig(),
  });

  poly.onAppEffect(async (msg) => {
    switch (msg.type) {
      case "login":
        await login(msg.config);
        poly.sendMessage("LoggedIn", true);
        break;
    }
  });

  poly.init();
})();
