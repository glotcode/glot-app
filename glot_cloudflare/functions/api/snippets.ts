type StringRecord = Record<string, string>;

interface Env {
  DB: D1Database;
}

interface Snippet {
  id: string;
  user_id: string | null;
  slug: string;
  language: string;
  title: string;
  visibility: string;
  stdin: string;
  run_command: string;
  spam_classification: String;
  files: File[];
  created_at: string;
  updated_at: string;
}

enum SpamClassification {
  NotSpam = "not_spam",
  Suspected = "suspected",
  Spam = "spam",
}

interface File {
  id: string;
  snippet_id: string;
  user_id: string | null;
  name: string;
  content: string;
  created_at: string;
  updated_at: string;
}

interface UnsavedSnippet {
  language: string;
  title: string;
  visibility: string;
  stdin: string;
  run_command: string;
  files: File[];
}

interface UnsavedFile {
  name: string;
  content: string;
}

export const onRequestPost: PagesFunction<Env & StringRecord> = async (
  context
) => {
  const db = context.env.DB;
  const now = Date.now();

  const unsavedSnippet = (await context.request.json()) as UnsavedSnippet;
  const user_id = null;
  const snippet = toSnippet(unsavedSnippet, now, user_id);
  console.log("snippet", snippet);

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
  snippetRow.files = rows.map((row) => row.results[0] as File);

  return new Response(JSON.stringify(snippetRow), {
    headers: {
      "Content-Type": "application/json",
    },
  });
};

function toSnippet(
  unsavedSnippet: UnsavedSnippet,
  timestamp: number,
  user_id: string
): Snippet {
  const id = crypto.randomUUID();
  const date = new Date(timestamp);

  return {
    id,
    user_id: user_id,
    slug: newSlug(timestamp),
    language: unsavedSnippet.language,
    title: unsavedSnippet.title,
    visibility: unsavedSnippet.visibility,
    stdin: unsavedSnippet.stdin,
    run_command: unsavedSnippet.run_command,
    spam_classification: SpamClassification.NotSpam.toString(),
    files: unsavedSnippet.files.map((file) => toFile(file, id, user_id, date)),
    created_at: date.toISOString(),
    updated_at: date.toISOString(),
  };
}

function toFile(
  unsavedFile: UnsavedFile,
  snippet_id: string,
  user_id: string,
  date: Date
): File {
  return {
    id: crypto.randomUUID(),
    snippet_id: snippet_id,
    user_id: user_id,
    name: unsavedFile.name,
    content: unsavedFile.content,
    created_at: date.toISOString(),
    updated_at: date.toISOString(),
  };
}

function newSlug(timestamp: number): string {
  const microsecondsSinceEpoch = timestamp * 1000;
  return microsecondsSinceEpoch.toString(36);
}

function insertSnippet(db: D1Database, snippet: Snippet): D1PreparedStatement {
  return db
    .prepare(
      "insert into snippets (id, user_id, slug, language, title, visibility, stdin, run_command, spam_classification, created_at, updated_at) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) returning *"
    )
    .bind(
      snippet.id,
      snippet.user_id,
      snippet.slug,
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

function insertFile(db: D1Database, file: File): D1PreparedStatement {
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
