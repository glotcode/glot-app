CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY NOT NULL, email TEXT NOT NULL, username TEXT NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_createdAt ON users(createdAt);
CREATE INDEX IF NOT EXISTS idx_users_updatedAt ON users(updatedAt);

CREATE TABLE IF NOT EXISTS snippets (id TEXT PRIMARY KEY NOT NULL, userId TEXT, language TEXT NOT NULL, title TEXT NOT NULL, visibility TEXT NOT NULL, stdin TEXT NOT NULL, runCommand TEXT NOT NULL, spamClassification TEXT NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL, FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS idx_snippets_language ON snippets(language);
CREATE INDEX IF NOT EXISTS idx_snippets_visibility ON snippets(visibility);
CREATE INDEX IF NOT EXISTS idx_snippets_userId ON snippets(userId);
CREATE INDEX IF NOT EXISTS idx_snippets_spamClassification ON snippets(spamClassification);
CREATE INDEX IF NOT EXISTS idx_snippets_createdAt ON snippets(createdAt);
CREATE INDEX IF NOT EXISTS idx_snippets_updatedAt ON snippets(updatedAt);

CREATE TABLE IF NOT EXISTS files (id TEXT PRIMARY KEY NOT NULL, snippetId TEXT NOT NULL, userId TEXT, name TEXT NOT NULL, content TEXT NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL, FOREIGN KEY(snippetId) REFERENCES snippets(id) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE);
CREATE UNIQUE INDEX IF NOT EXISTS idx_files_snippetId_name ON files(snippetId,name);
CREATE INDEX IF NOT EXISTS idx_files_snippetId ON files(snippetId);
CREATE INDEX IF NOT EXISTS idx_files_userId ON files(userId);
CREATE INDEX IF NOT EXISTS idx_files_createdAt ON files(createdAt);
CREATE INDEX IF NOT EXISTS idx_files_updatedAt ON files(updatedAt);

CREATE TABLE IF NOT EXISTS magic_links (id TEXT PRIMARY KEY NOT NULL, email TEXT NOT NULL, status TEXT NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL);
CREATE INDEX IF NOT EXISTS idx_magic_links_email ON magic_links(email);
CREATE INDEX IF NOT EXISTS idx_magic_links_status ON magic_links(status);

CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY NOT NULL, userId TEXT NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL, FOREIGN KEY(userId) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS idx_sessions_userId ON sessions(userId);
