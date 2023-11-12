export { TextEncoding, generateKey, encrypt, decrypt };

enum TextEncoding {
  Base16 = "base16",
  Base64 = "base64",
}

enum Algorithm {
  AES256GCM = "aes256gcm",
}

function algorithmName(algorithm: Algorithm): string {
  switch (algorithm) {
    case Algorithm.AES256GCM:
      return "AES-GCM";
  }
}

function algorithmKeyOptions(
  algorithm: Algorithm
): SubtleCryptoGenerateKeyAlgorithm {
  switch (algorithm) {
    case Algorithm.AES256GCM:
      return {
        name: "AES-GCM",
        length: 256,
      };
  }
}

const DEFAULT_ALGORITHM = Algorithm.AES256GCM;

async function generateKey(): Promise<string> {
  const key = await crypto.subtle.generateKey(
    algorithmKeyOptions(DEFAULT_ALGORITHM),
    true,
    ["encrypt", "decrypt"]
  );

  const rawKey = await crypto.subtle.exportKey("raw", key as CryptoKey);
  return arrayToBase16(new Uint8Array(rawKey as ArrayBuffer));
}

async function encrypt(
  rawKey: string,
  encoding: TextEncoding,
  text: string
): Promise<string> {
  const key = await importKey(rawKey);
  const encoder = new TextEncoder();
  const encoded = encoder.encode(text);

  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt(
    {
      name: algorithmName(DEFAULT_ALGORITHM),
      iv: iv,
    },
    key,
    encoded
  );

  return toEncodedString(encoding, iv, new Uint8Array(ciphertext));
}

async function decrypt(rawKey: string, cipher: string): Promise<string> {
  const key = await importKey(rawKey);

  const [iv, ciphertext] = fromEncodedString(cipher);
  const decrypted = await crypto.subtle.decrypt(
    {
      name: algorithmName(DEFAULT_ALGORITHM),
      iv: iv,
    },
    key,
    ciphertext
  );

  const decoder = new TextDecoder();
  return decoder.decode(decrypted);
}

function importKey(rawKey: string): Promise<CryptoKey> {
  const keyBuffer = base16StringToArray(rawKey);

  return crypto.subtle.importKey(
    "raw",
    keyBuffer,
    { name: algorithmName(DEFAULT_ALGORITHM) },
    false,
    ["encrypt", "decrypt"]
  );
}

function toEncodedString(
  encoding: TextEncoding,
  iv: Uint8Array,
  ciphertext: Uint8Array
): string {
  switch (encoding) {
    case TextEncoding.Base16:
      return toBase16EncodedString(iv, ciphertext);

    case TextEncoding.Base64:
      return toBase64EncodedString(iv, ciphertext);
  }
}

function toBase16EncodedString(iv: Uint8Array, ciphertext: Uint8Array): string {
  const encodedIv = arrayToBase16(iv);
  const encodedCipher = arrayToBase16(ciphertext);
  return `$${DEFAULT_ALGORITHM}$${TextEncoding.Base16}$${encodedIv}$${encodedCipher}`;
}

function toBase64EncodedString(iv: Uint8Array, ciphertext: Uint8Array): string {
  const encodedIv = arrayToBase64(iv);
  const encodedCipher = arrayToBase64(ciphertext);
  return `$${DEFAULT_ALGORITHM}$${TextEncoding.Base64}$${encodedIv}$${encodedCipher}`;
}

function fromEncodedString(cipher: string): [Uint8Array, Uint8Array] {
  const [algorithm, encoding, encodedIv, encodedCipher] = cipher
    .split("$")
    .slice(1);

  if (algorithm !== DEFAULT_ALGORITHM) {
    throw new Error(`Unsupported algorithm: ${algorithm}`);
  }

  switch (encoding) {
    case TextEncoding.Base16:
      return fromBase16EncodedString(encodedIv, encodedCipher);

    case TextEncoding.Base64:
      return fromBase64EncodedString(encodedIv, encodedCipher);

    default:
      throw new Error(`Unsupported encoding: ${encoding}`);
  }
}

function fromBase16EncodedString(
  encodedIv: string,
  encodedCipher: string
): [Uint8Array, Uint8Array] {
  const iv = base16StringToArray(encodedIv);
  const ciphertext = base16StringToArray(encodedCipher);
  return [iv, ciphertext];
}

function fromBase64EncodedString(
  encodedIv: string,
  encodedCipher: string
): [Uint8Array, Uint8Array] {
  const iv = base64StringToArray(encodedIv);
  const ciphertext = base64StringToArray(encodedCipher);
  return [iv, ciphertext];
}

function arrayToBase64(arr: Uint8Array): string {
  return btoa(String.fromCharCode(...arr));
}

function arrayToBase16(arr: Uint8Array): string {
  return [...arr].map((x) => x.toString(16).padStart(2, "0")).join("");
}

function base16StringToArray(str: string): Uint8Array {
  const elements = str.match(/../g)!.map((byte) => parseInt(byte, 16));
  return new Uint8Array(elements);
}

function base64StringToArray(str: string): Uint8Array {
  return Uint8Array.from(atob(str), (c) => c.charCodeAt(0));
}
