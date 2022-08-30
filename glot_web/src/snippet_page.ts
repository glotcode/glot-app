import init from "../wasm/glot.js";
import { snippetPage } from "../wasm/glot";
import { Polyester, rustEnum } from "polyester";
import { defaultDebugConfig } from "polyester/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const polyester = new Polyester(snippetPage(), {
    loggerConfig: defaultDebugConfig(),
  });

  polyester.init();

  const editor = initAce("editor-0");

  editor.getSession().on("change", () => {
    const msg = rustEnum.tuple("EditorContentChanged", [editor.getValue()]);
    //polyester.send(msg);
  });
})();

function initAce(elemId: string): any {
  // @ts-ignore
  return ace.edit(elemId);
}
