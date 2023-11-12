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
  const userId = null;
  const snippet = snippetFromUnsaved(unsavedSnippet, now, userId);

  const insertSnippetStatement = insertSnippet(db, snippet);
  const insertFileStatements = snippet.files.map((file) =>
    insertFile(db, file)
  );

  await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    insertSnippetStatement,
    ...insertFileStatements,
  ]);

  return new Response(JSON.stringify(snippet), {
    headers: {
      "Content-Type": "application/json",
    },
  });
};

function insertSnippet(db: D1Database, snippet: Snippet): D1PreparedStatement {
  return db
    .prepare(
      "insert into snippets (id, userId, language, title, visibility, stdin, runCommand, spamClassification, createdAt, updatedAt) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    )
    .bind(
      snippet.id,
      snippet.userId,
      snippet.language,
      snippet.title,
      snippet.visibility,
      snippet.stdin,
      snippet.runCommand,
      snippet.spamClassification,
      snippet.createdAt,
      snippet.updatedAt
    );
}

function insertFile(db: D1Database, file: SnippetFile): D1PreparedStatement {
  return db
    .prepare(
      "insert into files (id, snippetId, userId, name, content, createdAt, updatedAt) values (?, ?, ?, ?, ?, ?, ?)"
    )
    .bind(
      file.id,
      file.snippetId,
      file.userId,
      file.name,
      file.content,
      file.createdAt,
      file.updatedAt
    );
}
