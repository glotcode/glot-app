import { expect, test } from "@playwright/test";

const time = { seconds: 100, nanos: 0 };
const explanation = {
  provider: "local", version: "local-v1", score: 75,
  signals: ["promotional_url", "contact_url", "multiple_urls"],
  neighbors: [{ id: "00000000-0000-4000-8000-000000000003", slug: "similar-snippet", revision: time, similarity: 0.95 }],
};
function detail(historical = false) {
  return { snippet: {
    id: "00000000-0000-4000-8000-000000000001", slug: "fixture-snippet",
    user: { id: "00000000-0000-4000-8000-000000000002", username: "owner" },
    title: "Promotional fixture", language: "javascript", visibility: "public",
    stdin: "", runInstructions: null, files: [{ name: "main.js", content: "console.log(1)" }],
    createdAt: time, updatedAt: time,
    runnability: { isRunnable: true, checkedAt: time, attempts: 1, lastError: null, failedAt: null },
    spamClassification: { decision: "block", confidence: 55, reasonCode: "promotional_content", classifiedAt: time, attempts: 1, lastError: null, failedAt: null,
      ...(historical ? {} : { explanation }) },
  } };
}

test("admin provider switching retains credentials and sends selected provider", async ({ page }) => {
  let saved: any = { baseUrl: "https://classifier.example", authToken: "secret" }; // Legacy response has no provider.
  const writes: any[] = [];
  await page.route("**/api/mux", async route => {
    const { action, data } = route.request().postDataJSON();
    if (action === "upsert_admin_spam_classifier_config") { saved = data; writes.push(data); }
    const response = action === "get_admin_snippet" ? detail() : saved;
    await route.fulfill({ json: { data: response } });
  });
  await page.goto("/harness/spam-admin.html");
  await expect(page.getByLabel(/^Provider/)).toHaveValue("external");
  await page.getByLabel(/^Provider/).selectOption("local");
  await expect(page.getByLabel(/^Base URL/)).toHaveValue("https://classifier.example");
  await expect(page.getByLabel(/^Auth token/)).toHaveValue("secret");
  await page.getByRole("button", { name: "Save", exact: true }).click();
  await expect.poll(() => writes.length).toBe(1);
  expect(writes[0]).toEqual({ provider: "local", baseUrl: "https://classifier.example", authToken: "secret" });
  await expect(page.getByText("75 / 100", { exact: true })).toBeVisible();
  await expect(page.getByText(/uncalibrated rule confidence/)).toBeVisible();
  await expect(page.getByRole("link", { name: "similar-snippet", exact: true })).toHaveAttribute("href", "/admin/snippets/similar-snippet");
  await expect(page.getByText("Likely spam", { exact: true })).toBeVisible();
});

test("admin local config accepts empty credentials and historical explanations stay unavailable", async ({ page }) => {
  const writes: any[] = [];
  await page.route("**/api/mux", async route => {
    const { action, data } = route.request().postDataJSON();
    if (action === "upsert_admin_spam_classifier_config") writes.push(data);
    await route.fulfill({ json: { data: action === "get_admin_snippet" ? detail(true) : action === "upsert_admin_spam_classifier_config" ? data : { provider: "external", baseUrl: "", authToken: "" } } });
  });
  await page.goto("/harness/spam-admin.html");
  await expect(page.getByText(/Explanation unavailable/)).toBeVisible();
  await page.getByLabel(/^Provider/).selectOption("local");
  await page.getByRole("button", { name: "Save", exact: true }).click();
  await expect.poll(() => writes.length).toBe(1);
  expect(writes[0]).toEqual({ provider: "local", baseUrl: "", authToken: "" });
  await page.getByLabel(/^Provider/).selectOption("external");
  await page.getByRole("button", { name: "Save", exact: true }).click();
  await expect(page.getByText("Base URL must not be empty.", { exact: true })).toBeVisible();
  expect(writes).toHaveLength(1);
});
