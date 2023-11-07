import {
  Snippet,
  SnippetFile,
  UnsavedSnippet,
  snippetFromUnsaved,
} from "../../src/snippet";

type StringRecord = Record<string, string>;

interface Env {
  DB: D1Database;
}

export const onRequestPost: PagesFunction<Env & StringRecord> = async (
  context
) => {
  const db = context.env.DB;
  const now = Date.now();

  const unsavedSnippet = (await context.request.json()) as UnsavedSnippet;
  const user_id = null;
  const snippet = snippetFromUnsaved(unsavedSnippet, now, user_id);

  const insertSnippetStatement = insertSnippet(db, snippet);
  const insertFileStatements = snippet.files.map((file) =>
    insertFile(db, file)
  );

  const rows = await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    insertSnippetStatement,
    ...insertFileStatements,
  ]);

  rows.shift(); // ignore pragma result
  const snippetRow = rows.shift().results[0] as Snippet;
  snippetRow.files = rows.map((row) => row.results[0] as SnippetFile);

  return new Response(JSON.stringify(snippetRow), {
    headers: {
      "Content-Type": "application/json",
    },
  });
};

function insertSnippet(db: D1Database, snippet: Snippet): D1PreparedStatement {
  return db
    .prepare(
      "insert into snippets (id, user_id, language, title, visibility, stdin, run_command, spam_classification, created_at, updated_at) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) returning *"
    )
    .bind(
      snippet.id,
      snippet.user_id,
      snippet.language,
      snippet.title,
      snippet.visibility,
      snippet.stdin,
      snippet.run_command,
      snippet.spam_classification,
      snippet.created_at,
      snippet.updated_at
    );
}

function insertFile(db: D1Database, file: SnippetFile): D1PreparedStatement {
  return db
    .prepare(
      "insert into files (id, snippet_id, user_id, name, content, created_at, updated_at) values (?, ?, ?, ?, ?, ?, ?) returning *"
    )
    .bind(
      file.id,
      file.snippet_id,
      file.user_id,
      file.name,
      file.content,
      file.created_at,
      file.updated_at
    );
}
