import * as glot from "../../dist_backend/wasm_backend/glot";
import { getSnippet } from "../../src/snippet";

interface Env {
  DB: D1Database;
}

export const onRequest: PagesFunction<Env> = async (context) => {
  const snippet_id = context.params.id as string;
  const snippet = await getSnippet(context.env.DB, snippet_id);

  const page = glot.snippetPage(snippet, null, context.request.url);

  const { model, effects } = page.init();
  const html = page.view(model);

  return new Response(html, { headers: { "content-type": "text/html" } });
};
