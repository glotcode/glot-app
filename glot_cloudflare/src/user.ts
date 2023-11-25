export { User, newUser, saveUser, getUserById, getUserByEmail, randomUsername };

import { randomInt, randomWord } from "./random";

interface User {
  id: string;
  email: string;
  username: string;
  createdAt: string;
  updatedAt: string;
}

function newUser(email: string, username: string): User {
  const date = new Date();

  return {
    id: crypto.randomUUID(),
    email: email,
    username: username,
    createdAt: date.toISOString(),
    updatedAt: date.toISOString(),
  };
}

function randomUsername(): string {
  const firstWord = randomWord();
  const secondWord = randomWord();
  const num = randomInt(10, 99);

  return `${firstWord}${secondWord}${num}`;
}

async function saveUser(db: D1Database, user: User): Promise<void> {
  await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    insertUserStatement(db, user),
  ]);
}

async function getUserById(db: D1Database, id: string): Promise<User | null> {
  const statement = getUserByIdStatement(db, id);
  const row = await statement.first();

  if (row == null) {
    return null;
  }

  return row as unknown as User;
}

async function getUserByEmail(
  db: D1Database,
  id: string
): Promise<User | null> {
  const statement = getUserByEmailStatement(db, id);
  const row = await statement.first();

  if (row == null) {
    return null;
  }

  return row as unknown as User;
}

function insertUserStatement(db: D1Database, user: User): D1PreparedStatement {
  return db
    .prepare(
      "insert into users (id, email, username, createdAt, updatedAt) values (?, ?, ?, ?, ?)"
    )
    .bind(user.id, user.email, user.username, user.createdAt, user.updatedAt);
}

function getUserByIdStatement(db: D1Database, id: string): D1PreparedStatement {
  return db.prepare("select * from users where id = ? limit 1").bind(id);
}

function getUserByEmailStatement(
  db: D1Database,
  email: string
): D1PreparedStatement {
  return db.prepare("select * from users where email = ? limit 1").bind(email);
}
