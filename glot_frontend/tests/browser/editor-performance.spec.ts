import { expect, test } from "@playwright/test";

for (const [name, source] of [
  ["6250 lines", "const value = 1;\n".repeat(6250)],
  ["100KB single line", "// " + "x".repeat(99_997)],
  ["100KB minified code", "x=1;".repeat(25_000)],
] as const) {
  test(`performance: bulk insertion, sustained editing and undo (${name})`, async ({ page }, info) => {
    test.setTimeout(120_000);
    await page.goto("/harness/editor.html");
    const measurements: { operation: string; ms: number }[] = [];
    async function insert(value: string, replace: boolean) {
      const ms = await page.locator("#code-editor-input").evaluate(async (node: HTMLTextAreaElement, { value, replace }) => {
        const start = performance.now();
        node.focus();
        if (replace) node.setSelectionRange(0, node.value.length);
        node.dispatchEvent(new InputEvent("beforeinput", { bubbles: true, inputType: "insertFromPaste", data: value }));
        node.setRangeText(value, node.selectionStart, node.selectionEnd, "end");
        node.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertFromPaste", data: value }));
        await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
        return performance.now() - start;
      }, { value, replace });
      measurements.push({ operation: replace ? "bulk insert" : "edit", ms });
      return ms;
    }
    await insert(source, true);
    await expect(page.locator("#harness-text")).toHaveText(source);
    // Edit the beginning, forcing suffix reconciliation on the long line.
    await page.locator("#code-editor-input").evaluate((node: HTMLTextAreaElement) => node.setSelectionRange(0, 0));
    for (let i = 0; i < 50; i++) await insert("x", false);
    await expect(page.locator("#code-editor-input")).toHaveValue("x".repeat(50) + source);
    await expect(page.locator("#harness-text")).toHaveText("x".repeat(50) + source);
    if (name === "100KB minified code") {
      await page.locator("#code-editor-input").evaluate((node: HTMLTextAreaElement) => {
        node.scrollLeft = node.scrollWidth / 2;
        node.dispatchEvent(new Event("scroll", { bubbles: true }));
      });
      await expect.poll(() => page.locator(".code-editor__line span").count()).toBeLessThan(1000);
      await expect.poll(() => page.locator(".code-editor__token--number").count()).toBeGreaterThan(0);
      await expect(page.locator(".code-editor__line")).toHaveText("x".repeat(50) + source);
    }
    await page.keyboard.press("ControlOrMeta+z");
    await expect(page.locator("#harness-text")).not.toHaveText("x".repeat(50) + source);
    await info.attach("browser-timings.json", { body: JSON.stringify(measurements, null, 2), contentType: "application/json" });
    console.log(`${info.project.name} ${name}: bulk=${measurements[0].ms.toFixed(0)}ms, edit max=${Math.max(...measurements.slice(1).map(m => m.ms)).toFixed(0)}ms`);
    expect(measurements[0].ms).toBeLessThan(3000);
    expect(Math.max(...measurements.slice(1).map(m => m.ms))).toBeLessThan(1000);
  });
}

test("performance: replace all across 6250 lines is one undoable edit", async ({ page }, info) => {
  test.setTimeout(90_000);
  const source = "const value = 1;\n".repeat(6250);
  await page.goto("/harness/editor.html");
  await page.locator("#code-editor-input").evaluate((node: HTMLTextAreaElement, source) => {
    node.value = source; node.setSelectionRange(0, 0);
    node.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertFromPaste" }));
  }, source);
  await expect(page.locator("#harness-text")).toHaveText(source);
  await page.locator("#code-editor-input").focus();
  await page.keyboard.press("ControlOrMeta+f");
  await page.locator("#code-editor-search-field").fill("value");
  await page.locator("#code-editor-replace-field").fill("item");
  const start = Date.now();
  await page.getByRole("button", { name: "Replace all", exact: true }).click();
  await expect(page.locator("#harness-text")).toHaveText(source.replaceAll("value", "item"));
  const ms = Date.now() - start;
  console.log(`${info.project.name} replace 6250 matches: ${ms}ms`);
  await info.attach("replace-all-timing.json", { body: JSON.stringify({ ms }), contentType: "application/json" });
  await page.keyboard.press("Escape"); await page.locator("#code-editor-input").focus();
  await page.keyboard.press("ControlOrMeta+z");
  await expect(page.locator("#code-editor-input")).toHaveValue(source);
  expect(ms).toBeLessThan(5000);
});

test("native clipboard: 100KB paste reaches the model intact", async ({ page, browserName }) => {
  test.skip(browserName === "webkit", "WebKit denies clipboard permissions headlessly");
  const source = "const value = 1;\n".repeat(6250);
  await page.goto("/harness/editor.html");
  await page.evaluate(source => {
    const copy = document.createElement("textarea"); copy.id = "clipboard-source";
    copy.value = source; document.body.append(copy); copy.select();
  }, source);
  await page.keyboard.press("ControlOrMeta+c");
  await page.locator("#code-editor-input").focus();
  await page.keyboard.press("ControlOrMeta+a");
  await page.keyboard.press("ControlOrMeta+v");
  await expect(page.locator("#code-editor-input")).toHaveValue(source);
  await expect(page.locator("#harness-text")).toHaveText(source);
});
