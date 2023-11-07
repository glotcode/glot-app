export {
  Snippet,
  SnippetFile,
  UnsavedSnippet,
  UnsavedFile,
  SpamClassification,
  snippetFromUnsaved,
  fileFromUnsaved,
  getSnippet,
};

interface Snippet {
  id: string;
  user_id: string | null;
  language: string;
  title: string;
  visibility: string;
  stdin: string;
  run_command: string;
  spam_classification: String;
  files: SnippetFile[];
  created_at: string;
  updated_at: string;
}

enum SpamClassification {
  NotSpam = "not_spam",
  Suspected = "suspected",
  Spam = "spam",
}

interface SnippetFile {
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
  files: UnsavedFile[];
}

interface UnsavedFile {
  name: string;
  content: string;
}

function snippetFromUnsaved(
  unsavedSnippet: UnsavedSnippet,
  timestamp: number,
  user_id: string
): Snippet {
  const id = newSnippetId(timestamp);
  const date = new Date(timestamp);

  return {
    id,
    user_id: user_id,
    language: unsavedSnippet.language,
    title: unsavedSnippet.title,
    visibility: unsavedSnippet.visibility,
    stdin: unsavedSnippet.stdin,
    run_command: unsavedSnippet.run_command,
    spam_classification: SpamClassification.NotSpam.toString(),
    files: unsavedSnippet.files.map((file) =>
      fileFromUnsaved(file, id, user_id, date)
    ),
    created_at: date.toISOString(),
    updated_at: date.toISOString(),
  };
}

function fileFromUnsaved(
  unsavedFile: UnsavedFile,
  snippet_id: string,
  user_id: string,
  date: Date
): SnippetFile {
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

async function getSnippet(
  db: D1Database,
  snippet_id: string
): Promise<Snippet> {
  const rows = await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    selectSnippet(db, snippet_id),
    selectFiles(db, snippet_id),
  ]);

  rows.shift(); // ignore pragma result
  const snippet = rows.shift().results[0] as Snippet;
  snippet.files = rows.map((row) => row.results[0] as SnippetFile);

  return snippet;
}

function selectSnippet(db: D1Database, id: string): D1PreparedStatement {
  return db.prepare("select * from snippets where id = ?").bind(id);
}

function selectFiles(db: D1Database, snippet_id: string): D1PreparedStatement {
  return db
    .prepare("select * from files where snippet_id = ?")
    .bind(snippet_id);
}

// Create a new snippet id, which is the base36 encoding of the microseconds since the epoch.
// Since it's not possible to get microsecond precision in JS, we add a random number to reduce the chance of a collision.
function newSnippetId(timestamp: number): string {
  const microsecondsSinceEpoch = timestamp * 1000 + randomInt(0, 999);
  return microsecondsSinceEpoch.toString(36);
}

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1) + min);
}
