import { getSnippet } from "../../../src/snippet";

interface Env {
  DB: D1Database;
}

export const onRequest: PagesFunction<Env> = async (context) => {
  const snippet_id = context.params.id as string;
  const snippet = await getSnippet(context.env.DB, snippet_id);

  return new Response(JSON.stringify(snippet), {
    headers: {
      "content-type": "application/json",
    },
  });
};
