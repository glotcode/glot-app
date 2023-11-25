export {
  Session,
  SessionData,
  newSession,
  encryptSession,
  decryptSession,
  saveSession,
  getSessionById,
};

import { TextEncoding, decrypt, encrypt } from "./crypto";

interface Session {
  id: string;
  userId: string;
  createdAt: string;
  updatedAt: string;
}

function newSession(userId: string) {
  const date = new Date();

  return {
    id: crypto.randomUUID(),
    userId: userId,
    createdAt: date.toISOString(),
    updatedAt: date.toISOString(),
  };
}

interface SessionData {
  id: string;
  userId: string;
}

function encryptSession(
  encryptionKey: string,
  session: Session
): Promise<string> {
  const sessionData: SessionData = {
    id: session.id,
    userId: session.userId,
  };

  return encrypt(
    encryptionKey,
    TextEncoding.Base64,
    JSON.stringify(sessionData)
  );
}

async function decryptSession(
  encryptionKey: string,
  str: string
): Promise<SessionData> {
  const data = await decrypt(encryptionKey, str);
  return JSON.parse(data) as SessionData;
}

async function saveSession(db: D1Database, session: Session): Promise<void> {
  await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    insertSessionStatement(db, session),
  ]);
}

async function getSessionById(
  db: D1Database,
  id: string
): Promise<Session | null> {
  const statement = getSessionByIdStatement(db, id);
  const row = await statement.first();

  if (row == null) {
    return null;
  }

  return row as unknown as Session;
}

function insertSessionStatement(
  db: D1Database,
  session: Session
): D1PreparedStatement {
  return db
    .prepare(
      "insert into sessions (id, userId, createdAt, updatedAt) values (?, ?, ?, ?)"
    )
    .bind(session.id, session.userId, session.createdAt, session.updatedAt);
}

function getSessionByIdStatement(
  db: D1Database,
  id: string
): D1PreparedStatement {
  return db.prepare("select * from sessions where id = ? limit 1").bind(id);
}
