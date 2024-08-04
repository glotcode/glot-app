import * as glot from "../dist_backend/wasm_backend/glot";

export async function onRequest({ request }) {
    const route = glot.getRouteName(request.url);
    const { page, status } = getPageConfig(route, request);

    const { model, effects } = page.init();
    const html = page.view(model);

    return new Response(html, {
        status,
        headers: {
            "content-type": "text/html",
            "cache-control": "no-store",
            "pragma": "no-cache",
            "expires": "0",
        },
    });
}

interface PageConfig {
    page: any;
    status: number;
}

function getPageConfig(route: string, request: any): PageConfig {
    const windowSize = null;
    const url = request.url;
    const userAgent = request.headers.get("user-agent");

    switch (route) {
        case "NotFound":
            return {
                page: glot.notFoundPage(userAgent, url),
                status: 404,
            }

        case "Home":
            return {
                page: glot.homePage(userAgent, url),
                status: 200,
            }

        case "NewSnippet":
            return {
                page: glot.snippetPage(windowSize, userAgent, url),
                status: 200,
            }

        case "EditSnippet":
            return {
                page: glot.snippetPage(windowSize, userAgent, url),
                status: 200,
            }
    }

    throw new Error(`Unhandled route: ${route}`);
}