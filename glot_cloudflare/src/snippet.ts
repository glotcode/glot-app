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
  userId: string | null;
  language: string;
  title: string;
  visibility: string;
  stdin: string;
  runCommand: string;
  spamClassification: String;
  files: SnippetFile[];
  createdAt: string;
  updatedAt: string;
}

enum SpamClassification {
  NotSpam = "notSpam",
  Suspected = "suspected",
  Spam = "spam",
}

interface SnippetFile {
  id: string;
  snippetId: string;
  userId: string | null;
  name: string;
  content: string;
  createdAt: string;
  updatedAt: string;
}

interface UnsavedSnippet {
  language: string;
  title: string;
  visibility: string;
  stdin: string;
  runCommand: string;
  files: UnsavedFile[];
}

interface UnsavedFile {
  name: string;
  content: string;
}

function snippetFromUnsaved(
  unsavedSnippet: UnsavedSnippet,
  timestamp: number,
  userId: string
): Snippet {
  const id = newSnippetId(timestamp);
  const date = new Date(timestamp);

  return {
    id,
    userId: userId,
    language: unsavedSnippet.language,
    title: unsavedSnippet.title,
    visibility: unsavedSnippet.visibility,
    stdin: unsavedSnippet.stdin,
    runCommand: unsavedSnippet.runCommand,
    spamClassification: SpamClassification.NotSpam.toString(),
    files: unsavedSnippet.files.map((file) =>
      fileFromUnsaved(file, id, userId, date)
    ),
    createdAt: date.toISOString(),
    updatedAt: date.toISOString(),
  };
}

function fileFromUnsaved(
  unsavedFile: UnsavedFile,
  snippetId: string,
  userId: string,
  date: Date
): SnippetFile {
  return {
    id: crypto.randomUUID(),
    snippetId,
    userId,
    name: unsavedFile.name,
    content: unsavedFile.content,
    createdAt: date.toISOString(),
    updatedAt: date.toISOString(),
  };
}

async function getSnippet(db: D1Database, snippetId: string): Promise<Snippet> {
  const rows = await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    selectSnippet(db, snippetId),
    selectFiles(db, snippetId),
  ]);

  rows.shift(); // ignore pragma result
  const snippet = rows.shift().results[0] as Snippet;
  snippet.files = rows.map((row) => row.results[0] as SnippetFile);

  return snippet;
}

function selectSnippet(db: D1Database, id: string): D1PreparedStatement {
  return db.prepare("select * from snippets where id = ?").bind(id);
}

function selectFiles(db: D1Database, snippetId: string): D1PreparedStatement {
  return db.prepare("select * from files where snippetId = ?").bind(snippetId);
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
