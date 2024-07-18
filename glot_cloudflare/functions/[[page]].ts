import * as glot from "../dist_backend/wasm_backend/glot";

export async function onRequest({ request }) {
    const route = glot.getRouteName(request.url);
    const { page, status } = getPageConfig(route, request.url);

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

function getPageConfig(route: string, url: any): PageConfig {
    const windowSize = null;

    switch (route) {
        case "NotFound":
            return {
                page: glot.notFoundPage(url),
                status: 404,
            }

        case "Home":
            return {
                page: glot.homePage(url),
                status: 200,
            }

        case "NewSnippet":
            return {
                page: glot.snippetPage(windowSize, url),
                status: 200,
            }

        case "EditSnippet":
            return {
                page: glot.snippetPage(windowSize, url),
                status: 200,
            }
    }

    throw new Error(`Unhandled route: ${route}`);
}