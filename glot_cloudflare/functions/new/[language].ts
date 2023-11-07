import * as glot from "../../dist_backend/wasm_backend/glot";

export async function onRequest({ request }) {
  const page = glot.snippetPage(null, null, request.url);

  const { model, effects } = page.init();
  const html = page.view(model);

  return new Response(html, { headers: { "content-type": "text/html" } });
}
