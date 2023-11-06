-- Migration number: 0000 	 2023-11-05T22:09:23.186Z

CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY NOT NULL, email TEXT NOT NULL, username TEXT NOT NULL, name TEXT NOT NULL, password_hash TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_updated_at ON users(updated_at);

CREATE TABLE IF NOT EXISTS snippets (id TEXT PRIMARY KEY NOT NULL, user_id TEXT, slug TEXT NOT NULL, language TEXT NOT NULL, title TEXT NOT NULL, visibility TEXT NOT NULL, stdin TEXT NOT NULL, run_command TEXT NOT NULL, spam_classification TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE);
CREATE UNIQUE INDEX IF NOT EXISTS idx_snippets_slug ON snippets(slug);
CREATE INDEX IF NOT EXISTS idx_snippets_language ON snippets(language);
CREATE INDEX IF NOT EXISTS idx_snippets_visibility ON snippets(visibility);
CREATE INDEX IF NOT EXISTS idx_snippets_user_id ON snippets(user_id);
CREATE INDEX IF NOT EXISTS idx_snippets_spam_classification ON snippets(spam_classification);
CREATE INDEX IF NOT EXISTS idx_snippets_created_at ON snippets(created_at);
CREATE INDEX IF NOT EXISTS idx_snippets_updated_at ON snippets(updated_at);

CREATE TABLE IF NOT EXISTS files (id TEXT PRIMARY KEY NOT NULL, snippet_id TEXT NOT NULL, user_id TEXT, name TEXT NOT NULL, content TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(snippet_id) REFERENCES snippets(id) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE);
CREATE UNIQUE INDEX IF NOT EXISTS idx_files_snippet_id_name ON files(snippet_id,name);
CREATE INDEX IF NOT EXISTS idx_files_snippet_id ON files(snippet_id);
CREATE INDEX IF NOT EXISTS idx_files_user_id ON files(user_id);
CREATE INDEX IF NOT EXISTS idx_files_created_at ON files(created_at);
CREATE INDEX IF NOT EXISTS idx_files_updated_at ON files(updated_at);
