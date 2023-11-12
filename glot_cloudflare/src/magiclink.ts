export { MagicLink, newMagicLink, encryptMagicLink, saveMagicLink };

import { TextEncoding, encrypt } from "./crypto";

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

async function encryptMagicLink(
  encryptionKey: string,
  magicLink: MagicLink
): Promise<string> {
  return encrypt(encryptionKey, TextEncoding.Base16, magicLink.id);
}

async function saveMagicLink(
  db: D1Database,
  magicLink: MagicLink
): Promise<void> {
  await db.batch([
    db.prepare("PRAGMA foreign_keys = ON"),
    insertMagicLink(db, magicLink),
  ]);
}

function insertMagicLink(
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
