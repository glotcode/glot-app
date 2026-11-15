export type ThemePreference = "system" | "light" | "white" | "dark";

export const themeCookieName: "glot_theme";

export function readThemeCookie(cookieHeader: string): ThemePreference;

export function serializeThemeCookie(
  preference: ThemePreference,
  secure: boolean,
): string;
