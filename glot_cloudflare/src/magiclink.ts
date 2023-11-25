export {
  MagicLink,
  MagicLinkStatus,
  newMagicLink,
  encryptMagicLink,
  decryptMagicLink,
  getMagicLink,
  saveMagicLink,
  updateMagicLink,
  markMagicLinkAsUsed,
};

import { TextEncoding, decrypt, encrypt } from "./crypto";

interface MagicLink {
  id: string;
  email: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

enum MagicLinkStatus {
  Unused = "unused",
  Used = "used",
}

function newMagicLink(email: string): MagicLink {
  const date = new Date();

  return {
    id: crypto.randomUUID(),
    email: email,
    status: MagicLinkStatus.Unused,
    createdAt: date.toISOString(),
    updatedAt: date.toISOString(),
  };
}

function encryptMagicLink(
  encryptionKey: string,
  magicLink: MagicLink
): Promise<string> {
  return encrypt(encryptionKey, TextEncoding.Base16, magicLink.id);
}

function decryptMagicLink(encryptionKey: string, str: string): Promise<string> {
  return decrypt(encryptionKey, str);
}

async function saveMagicLink(
  db: D1Database,
  magicLink: MagicLink
): Promise<void> {
  await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    insertMagicLinkStatement(db, magicLink),
  ]);
}

async function getMagicLink(
  db: D1Database,
  id: string
): Promise<MagicLink | null> {
  const statement = getMagicLinkStatement(db, id);
  const row = await statement.first();

  if (row == null) {
    return null;
  }

  return row as unknown as MagicLink;
}

function markMagicLinkAsUsed(magicLink: MagicLink): MagicLink {
  const date = new Date();

  magicLink.status = MagicLinkStatus.Used;
  magicLink.updatedAt = date.toISOString();

  return magicLink;
}

async function updateMagicLink(
  db: D1Database,
  magicLink: MagicLink
): Promise<void> {
  await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    updateMagicLinkStatement(db, magicLink),
  ]);
}

function getMagicLinkStatement(
  db: D1Database,
  id: string
): D1PreparedStatement {
  return db.prepare("select * from magic_links where id = ? limit 1").bind(id);
}

function insertMagicLinkStatement(
  db: D1Database,
  magicLink: MagicLink
): D1PreparedStatement {
  return db
    .prepare(
      "insert into magic_links (id, email, status, createdAt, updatedAt) values (?, ?, ?, ?, ?)"
    )
    .bind(
      magicLink.id,
      magicLink.email,
      magicLink.status,
      magicLink.createdAt,
      magicLink.updatedAt
    );
}

function updateMagicLinkStatement(
  db: D1Database,
  magicLink: MagicLink
): D1PreparedStatement {
  return db
    .prepare("update magic_links set status = ?, updatedAt = ? where id = ?")
    .bind(magicLink.status, magicLink.updatedAt, magicLink.id);
}
