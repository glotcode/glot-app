import { expect, test, type Page } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";

// Opt in against a local backend and its development database. Uses the real
// production bundle, signed login cookies, API, persistence and runner.
const base = process.env.GLOT_E2E_BASE_URL;
const database = process.env.GLOT_E2E_DATABASE_URL;
test.skip(!base || !database, "Set GLOT_E2E_BASE_URL and GLOT_E2E_DATABASE_URL for local integration tests");

const input = "#code-editor-input";
const email = "editor-release-tests@example.test";
const created: string[] = [];

async function api(page: Page, action: string, data: unknown) {
  const response = await page.request.post(`${base}/api/mux`, { data: { action, data }, headers: { Origin: base! } });
  const result = await response.json();
  expect(response.ok(), JSON.stringify(result)).toBeTruthy();
  return result.data;
}
async function add(page: Page, name: string) {
  await page.getByRole("button", { name: "Add editor entry", exact: true }).click();
  const dialog = page.getByRole("dialog", { name: "Add editor entry" });
  if (name === "stdin") await dialog.getByRole("button", { name: "stdin", exact: true }).click();
  else await dialog.getByLabel("Filename", { exact: true }).fill(name);
  await dialog.getByRole("button", { name: "Add", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("");
}
async function tab(page: Page, name: string, value: string) {
  await page.getByRole("tab", { name: name === "stdin" ? "<stdin>" : name, exact: true }).click();
  await expect(page.locator(input)).toHaveValue(value);
}
async function editDialog(page: Page) {
  await page.getByRole("button", { name: /^(Edit selected file|Manage stdin tab)$/ }).click();
  return page.getByRole("dialog", { name: "Edit editor entry" });
}
async function save(page: Page, update = false) {
  const response = page.waitForResponse(r => r.url().endsWith("/api/mux") && r.request().postDataJSON()?.action === (update ? "update_snippet" : "create_snippet"));
  await page.getByRole("button", { name: "Save", exact: true }).click();
  if (!update) await page.getByRole("dialog", { name: "Save snippet" }).getByRole("button", { name: "Save", exact: true }).click();
  const received = await response;
  const result = await received.json();
  expect(received.ok(), JSON.stringify(result)).toBeTruthy();
  expect(received.request().postDataJSON().data.data.files).toEqual(result.data.files);
  created.push(result.data.slug);
  await expect(page).toHaveURL(`${base}/snippets/${result.data.slug}`);
  await expect(page.getByRole("button", { name: "Snippet info", exact: true })).toBeVisible();
  return result.data;
}
async function navigate(page: Page, path: string) {
  // An actual delegated anchor click exercises the SPA navigation observer.
  await page.evaluate(path => {
    const a = document.createElement("a"); a.href = path; a.textContent = "Test navigation";
    document.body.append(a); a.click(); a.remove();
  }, path);
  await expect(page).toHaveURL(`${base}${path}`);
}

test.beforeEach(async ({ page }) => {
  test.setTimeout(60_000);
  // Never seed login tokens against a remote environment.
  for (const value of [base!, database!]) expect(["localhost", "127.0.0.1", "[::1]"]).toContain(new URL(value).hostname);
  await page.route("**/ads/**", route => route.fulfill({ body: "", contentType: "text/html" }));
  const id = randomUUID(); const token = randomUUID();
  execFileSync("psql", [database!, "-v", "ON_ERROR_STOP=1", "-c",
    `INSERT INTO login_tokens (id,email,token,created_at) VALUES ('${id}','${email}','${token}',NOW())`], { stdio: "pipe" });
  try { await api(page, "login", { email, token }); }
  finally { execFileSync("psql", [database!, "-c", `DELETE FROM login_tokens WHERE id='${id}'`], { stdio: "pipe" }); }
});
test.afterEach(async ({ page }) => {
  for (const slug of new Set(created.splice(0))) await api(page, "delete_snippet", { slug });
  await api(page, "logout", {});
});

test("production: multi-file run, save, update and reload preserve exact payloads", async ({ page }) => {
  const main = "const fs = require('fs');\nconsole.log(require('./helper.js') + ':' + fs.readFileSync(0, 'utf8'));\n";
  const helper = "module.exports = '日本語 🦊';\n";
  const stdin = "input é";
  await page.goto(`${base}/new/javascript`);
  await page.locator(input).fill(main);
  await add(page, "helper.js"); await page.locator(input).fill(helper);
  await add(page, "stdin"); await page.locator(input).fill(stdin);
  const request = page.waitForRequest(r => r.url().endsWith("/api/mux") && r.postDataJSON()?.action === "run");
  await page.getByRole("button", { name: "Run", exact: true }).click();
  const sent = (await request).postDataJSON().data.payload;
  expect(sent.files).toEqual([{ name: "main.js", content: main }, { name: "helper.js", content: helper }]);
  expect(sent.stdin).toBe(stdin);
  await expect(page.locator("body")).toContainText("日本語 🦊:input é", { timeout: 30_000 });
  const saved = await save(page);
  expect(saved.files).toEqual(sent.files); expect(saved.stdin).toBe(stdin);
  await page.reload();
  await tab(page, "main.js", main); await tab(page, "helper.js", helper); await tab(page, "stdin", stdin);
  await page.locator(input).fill("changed stdin");
  const updated = await save(page, true); expect(updated.stdin).toBe("changed stdin");
  await page.reload(); await tab(page, "stdin", "changed stdin");
  const persisted = await api(page, "get_snippet", { slug: saved.slug });
  expect(persisted.files).toEqual(sent.files); expect(persisted.stdin).toBe("changed stdin");
});

test("production: navigation, Back/Forward and draft recovery isolate documents and history", async ({ page }) => {
  await page.goto(`${base}/new/javascript`);
  await page.locator(input).fill("// saved A\n"); const a = await save(page);
  await navigate(page, "/new/javascript");
  await expect(page.locator(input)).toHaveValue('console.log("Hello World!");');
  await page.locator(input).fill("// saved B\n"); const b = await save(page);
  await page.locator(input).fill("// draft B 🦊\n");
  await navigate(page, `/snippets/${a.slug}`); await expect(page.locator(input)).toHaveValue("// saved A\n");
  await page.locator(input).focus(); await page.keyboard.press("ControlOrMeta+z");
  await expect(page.locator(input)).toHaveValue("// saved A\n");
  await page.goBack(); await expect(page).toHaveURL(`${base}/snippets/${b.slug}`);
  await page.getByRole("dialog", { name: "Restore draft" }).getByRole("button", { name: "Yes", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("// draft B 🦊\n");
  await page.goForward(); await expect(page.locator(input)).toHaveValue("// saved A\n");
  await page.goto(`${base}/snippets/${b.slug}`);
  await page.getByRole("dialog", { name: "Restore draft" }).getByRole("button", { name: "Yes", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("// draft B 🦊\n");
  await page.reload();
  await page.getByRole("dialog", { name: "Restore draft" }).getByRole("button", { name: "No", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("// saved B\n");
});

test("production: add, rename and delete preserve surviving sessions and discard removed history", async ({ page }) => {
  await page.goto(`${base}/new/javascript`);
  await page.locator(input).fill("// first");
  await add(page, "second.js"); await page.locator(input).fill("// second");
  await add(page, "third.js"); await page.locator(input).fill("// third");
  const identity = await page.locator(input).getAttribute("data-session");
  const dialog = await editDialog(page);
  await dialog.getByLabel("Filename", { exact: true }).fill("renamed.js");
  await dialog.getByRole("button", { name: "Save", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("// third");
  await expect(page.locator(input)).toBeFocused();
  await page.keyboard.press("End"); await page.keyboard.insertText(" edited");
  await expect(page.locator(input)).toHaveValue("// third edited");
  await tab(page, "second.js", "// second");
  await (await editDialog(page)).getByRole("button", { name: "Delete file", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("// third edited");
  await expect(page.locator(input)).toHaveAttribute("data-session", identity!);
  await page.locator(input).focus(); await page.keyboard.press("ControlOrMeta+z");
  await expect(page.locator(input)).toHaveValue("// third");
  await (await editDialog(page)).getByRole("button", { name: "Delete file", exact: true }).click();
  await expect(page.locator(input)).toHaveValue("// first");
  await add(page, "stdin"); await page.locator(input).fill("old stdin");
  await (await editDialog(page)).getByRole("button", { name: /Remove|Delete/ }).click();
  await expect(page.locator(input)).toHaveValue("// first");
  await add(page, "stdin"); await page.locator(input).focus(); await page.keyboard.press("ControlOrMeta+z");
  await expect(page.locator(input)).toHaveValue("");
  await page.reload();
  await page.getByRole("dialog", { name: "Restore draft" }).getByRole("button", { name: "Yes", exact: true }).click();
  await tab(page, "main.js", "// first");
  await expect(page.getByRole("tab", { name: "second.js", exact: true })).toHaveCount(0);
});
