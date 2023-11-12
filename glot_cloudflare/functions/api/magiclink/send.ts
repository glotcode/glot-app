import {
  encryptMagicLink,
  newMagicLink,
  saveMagicLink,
} from "../../../src/magiclink";

type StringRecord = Record<string, string>;

interface Env {
  DB: D1Database;
}

export const onRequestPost: PagesFunction<Env & StringRecord> = async (
  context
) => {
  const payload = (await context.request.json()) as Payload;
  const magicLink = newMagicLink(payload.email);
  await saveMagicLink(context.env.DB, magicLink);
  const encryptedId = await encryptMagicLink(
    context.env.ENCRYPTION_KEY,
    magicLink
  );
  // TODO: if production, send email
  console.log("magic link:", encryptedId);

  return new Response();
};

interface Payload {
  email: string;
}
