import glot from "../dist_backend/wasm_backend/glot";

export async function onRequest({ request }) {
  const page = glot.homePage("http://example.com");
  const { model, effects } = page.init();

  const html = page.view(model);

  return new Response(html, { headers: { "content-type": "text/html" } });
}
