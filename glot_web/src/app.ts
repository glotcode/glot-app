import init, { getRouteName, notFoundPage, homePage, snippetPage } from "../wasm/glot";
import { BrowserWindow, Page, Poly } from "poly";
import { AceEditorElement } from "poly-ace-editor";
import { run } from "./api";
import { defaultDebugConfig } from "poly/src/logger";

AceEditorElement.register();

(async () => {
    await init("/wasm/glot_bg.wasm?hash=checksum");

    const route = getRouteName(location.href);
    const page = pageFromRoute(route)

    const poly = new Poly(page, {
        //loggerConfig: defaultDebugConfig(),
    });

    poly.onAppEffect(async (msg) => {
        switch (msg.type) {
            case "run":
                const runResponse = await run(msg.config);
                poly.sendMessage("GotRunResponse", runResponse);
                break;

            default:
                console.warn(`Unhandled app effect: ${msg.type}`);
        }
    });

    poly.init();
})();

function pageFromRoute(route: string): Page {
    const browserWindow = new BrowserWindow();
    const windowSize = browserWindow.getSize();

    switch (route) {
        case "NotFound":
            return notFoundPage(location.href)

        case "Home":
            return homePage(location.href)

        case "NewSnippet":
            return snippetPage(windowSize, location.href)

        case "EditSnippet":
            return snippetPage(windowSize, location.href)
    }

    throw new Error(`Unhandled route: ${route}`);
}



