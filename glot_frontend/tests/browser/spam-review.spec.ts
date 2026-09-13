import { expect, test, type Page } from "@playwright/test";

const time = { seconds: 100, nanos: 0 };
const admin = "00000000-0000-4000-8000-000000000002";
function fixture(slug: string, decision = "block", confidence: number | null = 75) {
  return { snippet: {
    id: "00000000-0000-4000-8000-000000000001", slug,
    user: { id: admin, username: "owner" }, title: `Snippet ${slug}`, language: "python", visibility: "public",
    stdin: "input <>&", runInstructions: { buildCommands: ["echo build"], runCommand: "python one.py" },
    files: [{ name: "one.py", content: "<script>window.injected=true</script>" }, { name: "two.py", content: "print('second file')" }],
    createdAt: time, updatedAt: time,
    runnability: { isRunnable: false, checkedAt: time, attempts: 1, lastError: null, failedAt: null },
    spamClassification: { decision, confidence, reasonCode: "link_spam", classifiedAt: time, attempts: 2, lastError: "prior failure", failedAt: time,
      explanation: { provider: "local", version: "local-v1", score: 75, signals: ["promotional_url"], neighbors: [] } },
  }, manualReview: { verdict: null as string | null, reviewerId: null as string | null, reviewedAt: null as typeof time | null, version: 0 } };
}

async function setup(page: Page) {
  const items = [fixture("c"), fixture("b", "review"), fixture("a", "allow", null)];
  const writes: any[] = [];
  const reads: any[] = [];
  const control = { failSave: false, failList: false, delaySave: 0 };
  await page.route("**/admin/spam-review*", route => route.fulfill({ contentType: "text/html", body:
    '<!doctype html><html lang="en"><head><title>Spam review</title></head><body><div id="app"></div><script type="module" src="/js/admin.ts"></script></body></html>' }));
  await page.route("**/api/mux", async route => {
    const { action, data } = route.request().postDataJSON();
    let value: any = null;
    if (action === "get_session") value = { id: admin, user: { id: admin, email: "admin@example.com", username: "admin", role: "admin" }, createdAt: time };
    if (action === "refresh_session") value = { nextHeartbeatInSeconds: 3600 };
    if (action === "get_admin_spam_review") {
      reads.push(data);
      if (control.failList) return route.fulfill({ status: 500, json: {} });
      const f = data.filter;
      let matching = items.filter(({ snippet: s, manualReview: m }) =>
        (f.decision === "all" || f.decision === "flagged" && ["review", "block"].includes(s.spamClassification.decision) || f.decision === s.spamClassification.decision)
        && (f.manual === "all" || f.manual === "unreviewed" && m.verdict === null || f.manual === m.verdict)
        && (f.reason === null || f.reason === s.spamClassification.reasonCode)
        && (f.confidenceMin === null || s.spamClassification.confidence !== null && s.spamClassification.confidence >= f.confidenceMin)
        && (f.confidenceMax === null || s.spamClassification.confidence !== null && s.spamClassification.confidence <= f.confidenceMax)
        && (f.username === null || s.user.username === f.username)
        && (f.language === null || s.language === f.language));
      if (data.focus) {
        value = { pageKind: "after", snippets: matching.filter(i => i.snippet.slug === data.focus), previousCursor: data.focus, nextCursor: data.focus };
      } else {
        if (data.pageKind === "after") matching = matching.filter(i => i.snippet.slug < data.cursor || data.inclusive && i.snippet.slug === data.cursor);
        if (data.pageKind === "before") matching = matching.filter(i => i.snippet.slug > data.cursor || data.inclusive && i.snippet.slug === data.cursor).reverse();
        const shown = matching.slice(0, 1);
        const cursor = shown[0]?.snippet.slug;
        value = data.pageKind === "before"
          ? { pageKind: "before", snippets: shown, previousCursor: matching.length > 1 ? cursor : null, nextCursor: cursor ?? data.cursor }
          : { pageKind: data.pageKind, snippets: shown, ...(data.pageKind === "after" ? { previousCursor: cursor ?? data.cursor } : {}), nextCursor: matching.length > 1 ? cursor : null };
      }
    }
    if (action === "save_admin_manual_review") {
      writes.push(data);
      if (control.delaySave) await new Promise(r => setTimeout(r, control.delaySave));
      if (control.failSave) return route.fulfill({ status: 500, json: {} });
      const item = items.find(i => i.snippet.slug === data.slug)!;
      if (data.expectedVersion !== item.manualReview.version || JSON.stringify(data.revision) !== JSON.stringify(item.snippet.updatedAt))
        return route.fulfill({ status: 409, json: { error: { code: "snippet_review_stale", message: "Snippet content or manual review changed; reload before reviewing again", requestId: admin } } });
      item.manualReview = { verdict: data.verdict, reviewerId: admin, reviewedAt: time, version: item.manualReview.version + 1 };
      value = item.manualReview;
    }
    await route.fulfill({ json: { data: value } });
  });
  return { items, reads, writes, control };
}

test("inline files, guarded save-and-advance, Undo, completion and keyboard controls", async ({ page }) => {
  const state = await setup(page);
  await page.goto("/admin/spam-review");
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  await expect(page.getByLabel("one.py", { exact: true })).toHaveText("<script>window.injected=true</script>");
  await expect(page.getByLabel("two.py", { exact: true })).toHaveText("print('second file')");
  await expect(page.getByLabel("stdin", { exact: true })).toHaveText("input <>&");
  await expect(page.getByLabel("Run instructions", { exact: true })).toContainText("python one.py");
  expect(await page.evaluate(() => (window as any).injected)).toBeUndefined();
  expect(state.reads[0].filter).toMatchObject({ decision: "flagged", manual: "unreviewed" });
  state.control.delaySave = 250;
  const spam = page.getByRole("button", { name: "Spam", exact: true });
  await spam.focus();
  await page.keyboard.press("Enter");
  await expect(page.getByRole("button", { name: "Not spam", exact: true })).toBeDisabled();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  expect(state.writes).toHaveLength(1);
  expect(state.writes[0]).toMatchObject({ slug: "c", expectedVersion: 0, revision: time });
  await expect(page).toHaveURL(/after=c/);
  await page.getByRole("button", { name: "Undo last review" }).click();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  expect(state.items[0].manualReview).toMatchObject({ verdict: null, version: 2 });
  await expect(page).toHaveURL(/focus=c/);
  await page.reload();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  await spam.click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Not spam", exact: true }).click();
  await expect(page.getByText(/Queue complete/)).toBeVisible();
  await expect(page.getByRole("button", { name: "Undo last review" })).toBeEnabled();
  await expect(page.getByRole("button", { name: "Previous", exact: true })).toBeEnabled();
  await page.getByRole("button", { name: "Undo last review" }).click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
});

test("filters reproduce on refresh/history and clear selects every snippet", async ({ page }) => {
  const { reads } = await setup(page);
  await page.goto("/admin/spam-review");
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  await page.getByLabel(/^Automated decision/).selectOption("review");
  await page.getByLabel(/^Reason code/).selectOption("link_spam");
  await page.getByLabel(/^Confidence minimum/).fill("75");
  await page.getByLabel(/^Confidence maximum/).fill("75");
  await page.getByLabel(/^Username/).fill("owner");
  await page.getByLabel(/^Language/).selectOption("python");
  await page.getByRole("button", { name: "Apply", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  expect(reads.at(-1).filter).toMatchObject({ decision: "review", reason: "link_spam", confidenceMin: 75, confidenceMax: 75, username: "owner", language: "python" });
  await page.reload();
  await expect(page.getByLabel(/^Confidence minimum/)).toHaveValue("75");
  await page.getByRole("button", { name: "Clear", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  expect(reads.at(-1).filter).toMatchObject({ decision: "all", manual: "all", confidenceMin: null });
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet a", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Previous", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  await page.goBack();
  await expect(page.getByRole("heading", { name: "Snippet a", exact: true })).toBeVisible();
});

test("save and load failures remain retryable; clearing and undo restore verdicts", async ({ page }) => {
  const state = await setup(page);
  state.items[0].manualReview.verdict = "spam";
  await page.goto("/admin/spam-review?decision=all&manual=all");
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  state.control.failSave = true;
  await page.getByRole("button", { name: "Clear manual verdict" }).click();
  await expect(page.getByText(/Could not save the review/)).toBeVisible();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  state.control.failSave = false;
  await page.getByRole("button", { name: "Clear manual verdict" }).click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Undo last review" }).click();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  expect(state.items[0].manualReview.verdict).toBe("spam");
  state.control.failList = true;
  await page.getByRole("button", { name: "Reload", exact: true }).click();
  await expect(page.getByRole("button", { name: "Retry loading" })).toBeVisible();
  state.control.failList = false;
  await page.getByRole("button", { name: "Retry loading" }).click();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
});

test("Previous from a completed all-snippets queue includes the last saved match", async ({ page }) => {
  await setup(page);
  await page.goto("/admin/spam-review?decision=all&manual=all&focus=a");
  await expect(page.getByRole("heading", { name: "Snippet a", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Not spam", exact: true }).click();
  await expect(page.getByText(/Queue complete/)).toBeVisible();
  await page.getByRole("button", { name: "Previous", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet a", exact: true })).toBeVisible();
});

test("concurrent reviews and edits reject stale saves and Undo without advancing", async ({ page }) => {
  const { items } = await setup(page);
  await page.goto("/admin/spam-review");
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  items[0].manualReview.version = 1;
  await page.getByRole("button", { name: "Spam", exact: true }).click();
  await expect(page.getByText(/Snippet content or manual review changed/)).toBeVisible();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Reload", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet c", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Spam", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  items[0].snippet.updatedAt = { seconds: 101, nanos: 0 };
  await page.getByRole("button", { name: "Undo last review" }).click();
  await expect(page.getByText(/Snippet content or manual review changed/)).toBeVisible();
  await expect(page.getByRole("heading", { name: "Snippet b", exact: true })).toBeVisible();
  expect(items[0].manualReview.verdict).toBe("spam");
});
