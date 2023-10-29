import glot from "../../../dist/wasm_backend/glot";

export async function onRequest({ request }) {
  // TODO: add function? glot.emptyWindowSize() -> None
  const page = glot.snippetPage(
    { width: 800, height: 600 },
    "http://example.com/new/rust"
  );

  const { model, effects } = page.init();
  const html = page.view(model);

  return new Response(html, { headers: { "content-type": "text/html" } });
}
