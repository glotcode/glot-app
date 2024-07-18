import * as glot from "../dist_backend/wasm_backend/glot";

export async function onRequest({ request }) {
    const route = glot.getRouteName(request.url);
    const page = pageFromRoute(route, request.url);

    const { model, effects } = page.init();

    const html = page.view(model);

    return new Response(html, { headers: { "content-type": "text/html" } });
}

function pageFromRoute(route: string, url: any): any {
    const windowSize = null;

    switch (route) {
        case "NotFound":
            return glot.notFoundPage(url)

        case "Home":
            return glot.homePage(url)

        case "NewSnippet":
            return glot.snippetPage(windowSize, url)

        case "EditSnippet":
            return glot.snippetPage(windowSize, url)
    }

    throw new Error(`Unhandled route: ${route}`);
}