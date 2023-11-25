import {
  MagicLink,
  MagicLinkStatus,
  decryptMagicLink,
  getMagicLink,
  markMagicLinkAsUsed,
  updateMagicLink,
} from "../../../src/magiclink";
import { encryptSession, newSession, saveSession } from "../../../src/session";
import {
  User,
  getUserByEmail,
  newUser,
  randomUsername,
  saveUser,
} from "../../../src/user";

type StringRecord = Record<string, string>;

interface Env {
  DB: D1Database;
}

export const onRequestPost: PagesFunction<Env & StringRecord> = async (
  context
) => {
  const payload = (await context.request.json()) as Payload;
  const magicLinkId = await decryptMagicLink(
    context.env.ENCRYPTION_KEY,
    payload.magicLink
  );
  const magicLink = await getMagicLink(context.env.DB, magicLinkId);

  // TODO: check expiration
  if (magicLink.status === MagicLinkStatus.Used) {
    return errorResponse(400, "Magic link has already been used");
  }

  const user = await getOrRegisterUser(context.env.DB, magicLink);

  const session = newSession(user.id);
  await saveSession(context.env.DB, session);
  const sessionString = await encryptSession(
    context.env.ENCRYPTION_KEY,
    session
  );

  const usedMagicLink = markMagicLinkAsUsed(magicLink);
  await updateMagicLink(context.env.DB, usedMagicLink);
  const expirationDate = getCookieExpirationDate();

  return new Response(JSON.stringify(user), {
    headers: {
      "Set-Cookie": `session=${sessionString}; HttpOnly; Secure; SameSite=Lax; Expires=${expirationDate.toUTCString()}`,
    },
  });
};

async function getOrRegisterUser(
  db: D1Database,
  magicLink: MagicLink
): Promise<User> {
  const user = await getUserByEmail(db, magicLink.email);
  if (user) {
    return user;
  } else {
    return registerNewUser(db, magicLink);
  }
}

async function registerNewUser(
  db: D1Database,
  magicLink: MagicLink
): Promise<User> {
  const username = randomUsername();
  const user = newUser(magicLink.email, username);
  await saveUser(db, user);

  return user;
}

interface Payload {
  magicLink: string;
}

function errorResponse(status: number, msg: string) {
  return new Response(JSON.stringify({ error: msg }), {
    status,
  });
}

function getCookieExpirationDate(): Date {
  const now = new Date();
  now.setFullYear(now.getFullYear() + 1);
  return now;
}
