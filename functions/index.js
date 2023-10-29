import glot from "../dist/wasm_backend/glot";

export async function onRequest({ request }) {
  const page = glot.homePage("http://example.com");
  const { model, effects } = page.init();

  const html = page.view(model);

  return new Response(html, { headers: { "content-type": "text/html" } });
}
