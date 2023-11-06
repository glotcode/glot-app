const usersTable: string = createTable("users", [
  "id TEXT PRIMARY KEY NOT NULL",
  "email TEXT NOT NULL",
  "username TEXT NOT NULL",
  "name TEXT NOT NULL",
  "password_hash TEXT NOT NULL",
  "created_at TEXT NOT NULL",
  "updated_at TEXT NOT NULL",
]);

const usersIndexes: string = [
  createIndex("users", ["email"], { unique: true }),
  createIndex("users", ["username"]),
  createIndex("users", ["created_at"]),
  createIndex("users", ["updated_at"]),
].join("\n");

const snippetsTable: string = createTable("snippets", [
  "id TEXT PRIMARY KEY NOT NULL",
  "user_id TEXT",
  "slug TEXT NOT NULL",
  "language TEXT NOT NULL",
  "title TEXT NOT NULL",
  "visibility TEXT NOT NULL",
  "stdin TEXT NOT NULL",
  "run_command TEXT NOT NULL",
  "suspected_spam INTEGER NOT NULL",
  "created_at TEXT NOT NULL",
  "updated_at TEXT NOT NULL",
  "FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE",
]);

const snippetsIndexes: string = [
  createIndex("snippets", ["slug"], { unique: true }),
  createIndex("snippets", ["language"]),
  createIndex("snippets", ["visibility"]),
  createIndex("snippets", ["user_id"]),
  createIndex("snippets", ["created_at"]),
  createIndex("snippets", ["updated_at"]),
].join("\n");

const filesTable: string = createTable("files", [
  "id TEXT PRIMARY KEY NOT NULL",
  "snippet_id TEXT NOT NULL",
  "user_id TEXT",
  "name TEXT NOT NULL",
  "content BLOB NOT NULL",
  "created_at TEXT NOT NULL",
  "updated_at TEXT NOT NULL",
  "FOREIGN KEY(snippet_id) REFERENCES snippets(id) ON UPDATE CASCADE ON DELETE CASCADE",
  "FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE",
]);

const filesIndexes: string = [
  createIndex("files", ["snippet_id", "name"], { unique: true }),
  createIndex("files", ["snippet_id"]),
  createIndex("files", ["user_id"]),
  createIndex("files", ["created_at"]),
  createIndex("files", ["updated_at"]),
].join("\n");

function createTable(name: string, fields: string[]): string {
  const joinedFields = fields.join(", ");
  return `CREATE TABLE IF NOT EXISTS ${name} (${joinedFields});`;
}

interface IndexOptions {
  unique?: boolean;
}

function createIndex(
  table: string,
  fields: string[],
  options?: IndexOptions
): string {
  const fieldsName = fields.join("_");
  const indexFields = fields.join(",");
  const unique = options?.unique ? "UNIQUE " : "";

  return `CREATE ${unique}INDEX IF NOT EXISTS idx_${table}_${fieldsName} ON ${table}(${indexFields});`;
}

const migrations = {
  initial: [
    usersTable,
    usersIndexes,
    snippetsTable,
    snippetsIndexes,
    filesTable,
    filesIndexes,
  ].join("\n\n"),
};

Object.entries(migrations).forEach(([name, migration]) => {
  console.log(`-- ${name} --`);
  console.log(migration);
});
