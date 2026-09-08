import { expect, test, type Page } from "@playwright/test";

const input = "#code-editor-input";
const contents = [
  "// alpha\nconst alpha = 1;\n",
  "// beta\nconst beta = '日本語 🦊 é';\n",
  "stdin: input only\nsecond line\n",
  "",
  "// delta\n" + "const delta = 4;\n".repeat(6250),
  "// epsilon\n\n\nconst epsilon = 5;\n",
  "// zeta\nconst zeta = 'six';",
  "// eta\nconst eta = 7;\n",
];

async function seed(page: Page) {
  await page.goto("/harness/editor.html");
  for (let index = 0; index < contents.length; index++) {
    await page.click(`#harness-tab-${index}`);
    if (contents[index] === "") {
      // Exercise the editor's own select-all/delete commands; Playwright fill("")
      // selects natively and immediately presses Delete before the select event.
      await page.locator(input).focus();
      await page.keyboard.press("ControlOrMeta+a");
      await page.keyboard.press("Backspace");
    } else {
      await page.locator(input).fill(contents[index]);
    }
    await expect.poll(() => page.locator("#harness-text").textContent()).toBe(contents[index]);
  }
}

async function verify(page: Page, index: number, expected: string) {
  await expect(page.locator(input)).toHaveAttribute("data-session", index === 2 ? "stdin" : `file-${index}`);
  await expect(page.locator(input)).toHaveValue(expected);
  await expect.poll(() => page.locator("#harness-text").textContent()).toBe(expected);
  const lines = expected.split("\n");
  await expect.poll(() => page.evaluate(() => {
    const numbers = [...document.querySelectorAll(".code-editor__line-number")];
    return [...document.querySelectorAll(".code-editor__line")].map((line, i) => ({
      index: Number(numbers[i]?.textContent) - 1,
      text: line.textContent,
    }));
  }).then(rows => rows.length === 0 ? ["no rendered lines"] : rows.filter(row =>
    row.index < 0 || row.index >= lines.length ||
    (row.text !== lines[row.index] && !(lines[row.index] === "" && row.text === " "))
  ))).toEqual([]);
}

test("stress: 160 tab switches keep full content and highlighted lines in agreement", async ({ page }) => {
  test.setTimeout(180_000);
  await seed(page);
  for (let step = 0; step < 160; step++) {
    const index = (step * 5 + Math.floor(step / 8)) % contents.length;
    await page.click(`#harness-tab-${index}`);
    await verify(page, index, contents[index]);
  }
});

test("stress: edits and undo remain isolated across 80 file switches", async ({ page }) => {
  test.setTimeout(180_000);
  await seed(page);
  const expected = [...contents];
  for (let step = 0; step < 80; step++) {
    const index = (step * 3) % contents.length;
    await page.click(`#harness-tab-${index}`);
    await page.locator(input).focus();
    await page.keyboard.press("ControlOrMeta+Home");
    const marker = `/* edit-${step}-file-${index} */`;
    const before = expected[index];
    await page.keyboard.insertText(marker);
    expected[index] = marker + before;
    await verify(page, index, expected[index]);

    await page.click(`#harness-tab-${(index + 1) % contents.length}`);
    await page.click(`#harness-tab-${index}`);
    await page.locator(input).focus();
    await page.keyboard.press("ControlOrMeta+z");
    await verify(page, index, before);
    await page.keyboard.press("ControlOrMeta+Shift+z");
    await verify(page, index, expected[index]);
  }
  for (let index = 0; index < expected.length; index++) {
    await page.click(`#harness-tab-${index}`);
    await verify(page, index, expected[index]);
  }
});

test("stress: same-frame tab switches and native edits never cross file boundaries", async ({ page }) => {
  test.setTimeout(180_000);
  await seed(page);
  const expected = [...contents];
  for (let batch = 0; batch < 20; batch++) {
    const operations = Array.from({ length: 20 }, (_, step) => ({
      index: (batch * 20 + step) % contents.length,
      marker: `/* burst-${batch}-${step} */`,
    }));
    const mismatches = await page.evaluate(({ operations, expected }) => {
      const errors: string[] = [];
      for (const { index, marker } of operations) {
        document.querySelector<HTMLButtonElement>(`#harness-tab-${index}`)!.click();
        const field = document.querySelector<HTMLTextAreaElement>("#code-editor-input")!;
        if (field.value !== expected[index]) errors.push(`wrong content for file ${index}`);
        field.setSelectionRange(0, 0);
        field.setRangeText(marker, 0, 0, "end");
        field.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText", data: marker }));
        expected[index] = marker + expected[index];
      }
      return errors;
    }, { operations, expected });
    expect(mismatches).toEqual([]);
    for (const { index, marker } of operations) expected[index] = marker + expected[index];
    const last = operations.at(-1)!.index;
    await verify(page, last, expected[last]);
  }
  for (let index = 0; index < expected.length; index++) {
    await page.click(`#harness-tab-${index}`);
    await verify(page, index, expected[index]);
  }
});
