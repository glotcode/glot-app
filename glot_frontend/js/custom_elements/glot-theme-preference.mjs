export const themeCookieName = "glot_theme";

const oneYearInSeconds = 31_536_000;

export function readThemeCookie(cookieHeader) {
  const prefix = `${themeCookieName}=`;

  for (const part of cookieHeader.split(";")) {
    const cookie = part.trim();
    if (!cookie.startsWith(prefix)) continue;

    try {
      const value = decodeURIComponent(cookie.slice(prefix.length));
      if (value === "light" || value === "white" || value === "dark") return value;
    } catch {
      // Malformed cookie values are treated as the system preference.
    }
  }

  return "system";
}

export function serializeThemeCookie(preference, secure) {
  const secureAttribute = secure ? "; Secure" : "";

  if (preference === "system") {
    return `${themeCookieName}=; Path=/; Max-Age=0; SameSite=Lax${secureAttribute}`;
  }

  return `${themeCookieName}=${encodeURIComponent(preference)}; Path=/; Max-Age=${oneYearInSeconds}; SameSite=Lax${secureAttribute}`;
}
