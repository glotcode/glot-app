import { defineConfig, devices } from "@playwright/test";

// The browser tests drive the real editor in a real browser. They are opt-in
// (`npm run test:browser`) so the default test run stays fast and needs no
// browser downloads.
export default defineConfig({
  testDir: "./tests/browser",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: {
    baseURL: "http://localhost:4173",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "npx vite --port 4173 --strictPort --host 127.0.0.1",
    url: "http://127.0.0.1:4173/harness/editor.html",
    stdout: "pipe",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
});
