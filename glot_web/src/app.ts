import init, { getRouteName, notFoundPage, homePage, snippetPage } from "../wasm/glot";
import { BrowserWindow, Page, Poly } from "poly";
import { AceEditorElement } from "poly-ace-editor";
import { run } from "./api";
import { defaultDebugConfig } from "poly/src/logger";

AceEditorElement.register();

(async () => {
    registerServiceWorker();

    await init("/wasm/glot_bg.wasm?hash=checksum");

    const route = getRouteName(location.href);
    const page = pageFromRoute(route)

    const poly = new Poly(page, {
        //loggerConfig: defaultDebugConfig(),
    });

    poly.onAppEffect(async (msg) => {
        switch (msg.type) {
            case "run":
                try {
                    const runResponse = await run(msg.config);
                    poly.sendMessage("GotRunResponse", runResponse);
                } catch (err: any) {
                    poly.sendMessage("GotRunResponse", {
                        message: err.message,
                    });
                }
                break;

            case "getLanguageVersion":
                try {
                    const runResponse = await run(msg.config);
                    poly.sendMessage("GotLanguageVersionResponse", runResponse);
                } catch (err: any) {
                    poly.sendMessage("LanguageVersionResponse", {
                        message: err.message,
                    });
                }
                break;

            default:
                console.warn(`Unhandled app effect: ${msg.type}`);
        }
    });

    poly.init();
})();

function pageFromRoute(route: string): Page {
    const browserWindow = new BrowserWindow();
    const browserContext = {
        windowSize: browserWindow.getSize(),
        userAgent: navigator.userAgent,
        currentUrl: location.href,
    }

    switch (route) {
        case "NotFound":
            return notFoundPage(browserContext)

        case "Home":
            return homePage(browserContext)

        case "NewSnippet":
            return snippetPage(browserContext)

        case "EditSnippet":
            return snippetPage(browserContext)
    }

    throw new Error(`Unhandled route: ${route}`);
}




async function registerServiceWorker() {
    if (!("serviceWorker" in navigator)) {
        return
    }

    await waitForIdle();

    navigator.serviceWorker.register("/sw.js?hash=checksum")
        .catch(err => {
            console.error("Service worker registration failed", err);
        });

}

function waitForIdle(): Promise<void> {
    if ("requestIdleCallback" in window) {
        return new Promise(resolve => {
            window.requestIdleCallback(() => {
                resolve();
            })
        });
    } else {
        return new Promise(resolve => {
            setTimeout(() => {
                resolve();
            }, 200);
        })
    }
}