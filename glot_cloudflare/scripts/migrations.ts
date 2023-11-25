const usersTable: string = createTable("users", [
  "id TEXT PRIMARY KEY NOT NULL",
  "email TEXT NOT NULL",
  "username TEXT NOT NULL",
  "createdAt TEXT NOT NULL",
  "updatedAt TEXT NOT NULL",
]);

const usersIndexes: string = [
  createIndex("users", ["email"], { unique: true }),
  createIndex("users", ["username"]),
  createIndex("users", ["createdAt"]),
  createIndex("users", ["updatedAt"]),
].join("\n");

const snippetsTable: string = createTable("snippets", [
  "id TEXT PRIMARY KEY NOT NULL",
  "userId TEXT",
  "language TEXT NOT NULL",
  "title TEXT NOT NULL",
  "visibility TEXT NOT NULL",
  "stdin TEXT NOT NULL",
  "runCommand TEXT NOT NULL",
  "spamClassification TEXT NOT NULL",
  "createdAt TEXT NOT NULL",
  "updatedAt TEXT NOT NULL",
  "FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE",
]);

const snippetsIndexes: string = [
  createIndex("snippets", ["language"]),
  createIndex("snippets", ["visibility"]),
  createIndex("snippets", ["userId"]),
  createIndex("snippets", ["spamClassification"]),
  createIndex("snippets", ["createdAt"]),
  createIndex("snippets", ["updatedAt"]),
].join("\n");

const filesTable: string = createTable("files", [
  "id TEXT PRIMARY KEY NOT NULL",
  "snippetId TEXT NOT NULL",
  "userId TEXT",
  "name TEXT NOT NULL",
  "content TEXT NOT NULL",
  "createdAt TEXT NOT NULL",
  "updatedAt TEXT NOT NULL",
  "FOREIGN KEY(snippetId) REFERENCES snippets(id) ON UPDATE CASCADE ON DELETE CASCADE",
  "FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE",
]);

const filesIndexes: string = [
  createIndex("files", ["snippetId", "name"], { unique: true }),
  createIndex("files", ["snippetId"]),
  createIndex("files", ["userId"]),
  createIndex("files", ["createdAt"]),
  createIndex("files", ["updatedAt"]),
].join("\n");

const magicLinksTable: string = createTable("magic_links", [
  "id TEXT PRIMARY KEY NOT NULL",
  "email TEXT NOT NULL",
  "status TEXT NOT NULL",
  "createdAt TEXT NOT NULL",
  "updatedAt TEXT NOT NULL",
]);

const magicLinksIndexes: string = [
  createIndex("magic_links", ["email"]),
  createIndex("magic_links", ["status"]),
].join("\n");

const sessionsTable: string = createTable("sessions", [
  "id TEXT PRIMARY KEY NOT NULL",
  "userId TEXT NOT NULL",
  "createdAt TEXT NOT NULL",
  "updatedAt TEXT NOT NULL",
  "FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE",
]);

const sessionsIndexes: string = [
  // fmt
  createIndex("sessions", ["userId"]),
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
    magicLinksTable,
    magicLinksIndexes,
    sessionsTable,
    sessionsIndexes,
  ].join("\n\n"),
};

Object.entries(migrations).forEach(([name, migration]) => {
  console.log(migration);
});
