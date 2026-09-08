import { expect, test, type Page } from "@playwright/test";

const editor = "#code-editor-input";
const harness = "/harness/editor.html";

async function open(page: Page, bindings?: string) {
  await page.goto(bindings ? `${harness}?bindings=${bindings}` : harness);
  await page.waitForSelector(editor);
  await page.click(editor);
}

async function value(page: Page) {
  return page.inputValue(editor);
}

function pattern(text: string) {
  return new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "s");
}

/// The editor writes the textarea back after paint, so assertions poll rather
/// than reading one snapshot.
async function expectContains(page: Page, text: string) {
  await expect(page.locator(editor)).toHaveValue(pattern(text));
}

async function expectMissing(page: Page, text: string) {
  await expect(page.locator(editor)).not.toHaveValue(pattern(text));
}

async function expectCaret(page: Page, at: number) {
  await expect.poll(() => caret(page)).toBe(at);
}

async function caret(page: Page) {
  return page.$eval(editor, (node) => (node as HTMLTextAreaElement).selectionStart);
}

async function setCaret(page: Page, at: number) {
  await page.$eval(
    editor,
    (node, offset) => {
      const field = node as HTMLTextAreaElement;
      field.setSelectionRange(offset, offset);
      field.dispatchEvent(new Event("select", { bubbles: true }));
    },
    at,
  );
}

test.describe("code editor", () => {
  test("holds the whole document and renders highlighted lines", async ({ page }) => {
    await open(page);

    await expectContains(page, "function greet(name)");
    await expect(page.locator(".code-editor__token--keyword").first()).toBeVisible();
    await expect(page.locator(".code-editor__line-number").first()).toHaveText("1");
  });

  test("every line number sits on its own line", async ({ page }) => {
    await open(page);

    const rows = await page.evaluate(() => {
      const numbers = [...document.querySelectorAll(".code-editor__line-number")];
      const lines = [...document.querySelectorAll(".code-editor__line")];
      return numbers.map((number, index) => ({
        number: number.textContent,
        numberTop: number.getBoundingClientRect().top,
        lineTop: lines[index]?.getBoundingClientRect().top ?? null,
      }));
    });

    expect(rows.length).toBeGreaterThan(1);
    for (const row of rows) {
      expect(row.lineTop, `line number ${row.number}`).toBeCloseTo(row.numberTop, 0);
    }
  });

  test("typing reaches the document and the page sees it immediately", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);
    await page.keyboard.type("const x = 1;\n");

    await expectContains(page, "const x = 1;");
    await expect(page.locator("#harness-text")).toContainText("const x = 1;");
  });

  test("no input is lost during a fast burst of typing", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);

    const burst = "abcdefghijklmnopqrstuvwxyz0123456789";
    await page.keyboard.type(burst, { delay: 0 });

    await expectContains(page, burst);
  });

  test("undo and redo are the editor's own, not the browser's", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);
    await page.keyboard.type("typed");
    await expectContains(page, "typed");

    await page.keyboard.press("ControlOrMeta+z");
    await expectMissing(page, "typed");

    await page.keyboard.press("ControlOrMeta+Shift+z");
    await expectContains(page, "typed");
  });

  test("selection, indentation and comment toggling work on a selection", async ({ page }) => {
    await open(page);
    await page.keyboard.press("ControlOrMeta+a");
    await page.keyboard.press("ControlOrMeta+/");

    await expectContains(page, "// // first file");
  });

  test("Tab indents and Escape then Tab leaves the editor", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);
    await page.keyboard.press("Tab");
    await expectContains(page, "  // first file");

    await page.keyboard.press("Escape");
    await page.keyboard.press("Control+m");
    await page.keyboard.press("Tab");
    await expect(page.locator(editor)).not.toBeFocused();
  });

  test("clipboard copy and paste round-trip", async ({ page, browserName }) => {
    test.skip(browserName === "webkit", "WebKit denies clipboard permissions headlessly");
    await open(page);
    await page.keyboard.press("ControlOrMeta+a");
    await page.keyboard.press("ControlOrMeta+c");
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("ControlOrMeta+v");

    await expect
      .poll(async () => (await value(page)).match(/first file/g)?.length ?? 0)
      .toBeGreaterThan(1);
  });

  test("text dropped into the editor is reconciled into the document", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);

    await page.$eval(editor, (node) => {
      const field = node as HTMLTextAreaElement;
      const transfer = new DataTransfer();
      transfer.setData("text/plain", "DROPPED");
      field.dispatchEvent(
        new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: transfer }),
      );
      // Browsers apply the drop themselves; mirror that and let the editor
      // reconcile the resulting value.
      field.value = `DROPPED${field.value}`;
      field.dispatchEvent(new Event("input", { bubbles: true }));
    });

    await expect(page.locator("#harness-text")).toContainText("DROPPED");
  });

  test("switching tabs keeps each file's own text, caret and history", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);
    await page.keyboard.type("FIRST");

    await page.click("#harness-tab-1");
    await expectContains(page, "second file");
    await expectMissing(page, "FIRST");

    await page.click("#harness-tab-0");
    await expectContains(page, "FIRST");
    await expectCaret(page, 5);
  });

  test("stdin has its own session and stays unhighlighted", async ({ page }) => {
    await open(page);
    await page.click("#harness-tab-2");

    await expectContains(page, "stdin text");
    await expect(page.locator(".code-editor__token--keyword")).toHaveCount(0);
  });

  test("read-only content cannot be edited but can be read and selected", async ({ page }) => {
    await open(page);
    await page.click("#harness-read-only");
    await page.click(editor);

    const before = await value(page);
    await page.keyboard.type("nope");
    await expect(page.locator(editor)).toHaveValue(before);

    await page.keyboard.press("ControlOrMeta+a");
    await expectCaret(page, 0);
  });

  test("Ctrl/Cmd-Enter runs the snippet with the text just typed", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);
    await page.keyboard.type("RUNME");
    await page.keyboard.press("ControlOrMeta+Enter");

    await expect(page.locator("#harness-ran")).toContainText("RUNME");
  });

  test("the search panel finds and replaces", async ({ page }) => {
    await open(page);
    await page.keyboard.press("ControlOrMeta+f");
    await expect(page.locator("#code-editor-search-field")).toBeFocused();

    await page.fill("#code-editor-search-field", "hello");
    await page.fill("#code-editor-replace-field", "goodbye");
    await page.click("text=Replace all");

    await expectContains(page, "goodbye");
  });

  test("the editor follows the page theme", async ({ page }) => {
    await open(page);
    const light = await page.locator(".code-editor").evaluate((node) =>
      getComputedStyle(node).backgroundColor,
    );

    await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
    const dark = await page.locator(".code-editor").evaluate((node) =>
      getComputedStyle(node).backgroundColor,
    );

    expect(dark).not.toBe(light);
  });

  test("focus is on a labelled multiline text box", async ({ page }) => {
    await open(page);
    await expect(page.locator(editor)).toBeFocused();
    await expect(page.locator(editor)).toHaveAttribute("aria-label", "Code editor");
    await expect(page.locator(editor)).toHaveAttribute("aria-multiline", "true");
    await expect(page.locator("#code-editor-status")).toHaveAttribute("role", "status");
  });

  test("Vim bindings drive modal editing", async ({ page }) => {
    await open(page, "vim");
    await setCaret(page, 0);

    await page.keyboard.press("d");
    await page.keyboard.press("d");
    await expectMissing(page, "// first file");

    await page.keyboard.press("i");
    await page.keyboard.type("inserted");
    await expectContains(page, "inserted");

    await page.keyboard.press("Escape");
    await page.keyboard.press("u");
    await expectMissing(page, "inserted");
  });

  test("Emacs bindings drive movement and the kill ring", async ({ page }) => {
    await open(page, "emacs");
    await setCaret(page, 0);

    await page.keyboard.press("Control+k");
    await expectMissing(page, "// first file");

    await page.keyboard.press("Control+y");
    await expectContains(page, "// first file");
  });

  test("composition is recorded as one undo operation", async ({ page }) => {
    await open(page);
    await setCaret(page, 0);

    await page.$eval(editor, (node) => {
      const field = node as HTMLTextAreaElement;
      field.dispatchEvent(new CompositionEvent("compositionstart", { bubbles: true }));
      field.value = `こん${field.value}`;
      field.setSelectionRange(2, 2);
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new CompositionEvent("compositionend", { bubbles: true }));
    });

    await expectContains(page, "こん");

    await page.click(editor);
    await page.keyboard.press("ControlOrMeta+z");
    await expectMissing(page, "こん");
  });
});


test("backward selections extend across key releases and tab switches", async ({ page }) => {
  await open(page);
  await setCaret(page, 10);
  for (let count = 1; count <= 3; count++) {
    await page.keyboard.press("Shift+ArrowLeft");
    await expect.poll(() => page.$eval(editor, (node) => {
      const field = node as HTMLTextAreaElement;
      return [field.selectionStart, field.selectionEnd, field.selectionDirection];
    })).toEqual([10 - count, 10, "backward"]);
  }
  await page.click("#harness-tab-1");
  await expectContains(page, "second file");
  await page.click("#harness-tab-0");
  await page.locator(editor).focus();
  await page.keyboard.press("Shift+ArrowLeft");
  await expect.poll(() => page.$eval(editor, (node) => {
    const field = node as HTMLTextAreaElement;
    return [field.selectionStart, field.selectionEnd, field.selectionDirection];
  })).toEqual([6, 10, "backward"]);
});

test("native backward selections preserve their active end", async ({ page }) => {
  await open(page);
  await page.$eval(editor, (node) => {
    const field = node as HTMLTextAreaElement;
    field.setSelectionRange(5, 10, "backward");
    field.dispatchEvent(new Event("select", { bubbles: true }));
  });
  await page.keyboard.press("Shift+ArrowLeft");
  await expect.poll(() => page.$eval(editor, (node) => {
    const field = node as HTMLTextAreaElement;
    return [field.selectionStart, field.selectionEnd, field.selectionDirection];
  })).toEqual([4, 10, "backward"]);
});

test("tab switches restore both scroll offsets independently of the caret", async ({ page }) => {
  await open(page);
  await page.locator(editor).fill(Array.from({ length: 100 }, (_, i) =>
    `line ${i} ${"x".repeat(150)}`).join("\n"));
  await expect(page.locator("#harness-text")).toContainText("line 99");
  await setCaret(page, 0);
  await page.locator(editor).blur();
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.$eval(editor, (node) => { node.scrollTop = 1200; node.scrollLeft = 100; });
  const offsets = () => page.$eval(editor, (node) => [node.scrollTop, node.scrollLeft]);
  await expect.poll(offsets).toEqual([1200, 100]);
  await expect(page.locator(".code-editor__lines")).toHaveCSS("transform", /-100/);
  await page.click("#harness-tab-1");
  await expectContains(page, "second file");
  await expect.poll(offsets).toEqual([0, 0]);
  await page.click("#harness-tab-0");
  await expectContains(page, "line 99");
  await expect.poll(offsets).toEqual([1200, 100]);
  await expectCaret(page, 0);
});

for (const bindings of ["default", "vim", "emacs"]) {
  test(`composition keys leave pending text intact with ${bindings} bindings`, async ({ page }) => {
    await open(page, bindings);
    await setCaret(page, 0);
    if (bindings === "vim") await page.keyboard.press("i");
    const before = await value(page);
    await page.$eval(editor, (node) => {
      node.dispatchEvent(new CompositionEvent("compositionstart", { bubbles: true }));
    });
    // Let the composing model render as well as exercising isComposing below.
    await page.evaluate(() => new Promise(requestAnimationFrame));
    const prevented = await page.$eval(editor, (node) => {
      const field = node as HTMLTextAreaElement;
      field.value = `こん${field.value}`;
      field.setSelectionRange(2, 2);
      field.dispatchEvent(new InputEvent("input", {
        bubbles: true, isComposing: true, inputType: "insertCompositionText",
      }));
      return ["ArrowLeft", "Backspace", "Enter", "Escape"].map(key => {
        const event = new KeyboardEvent("keydown", {
          key, isComposing: true, bubbles: true, cancelable: true,
        });
        field.dispatchEvent(event);
        return event.defaultPrevented;
      });
    });
    expect(prevented).toEqual([false, false, false, false]);
    await expect(page.locator(editor)).toHaveValue(`こん${before}`);
    await page.$eval(editor, (node) => {
      node.dispatchEvent(new CompositionEvent("compositionend", { bubbles: true }));
    });
    await expect(page.locator("#harness-text")).toContainText(`こん${before}`);
    if (bindings === "vim") {
      await page.keyboard.press("Escape");
      await expect(page.locator(".code-editor__status-mode")).toContainText("NORMAL");
    }
    await page.keyboard.press(bindings === "vim" ? "u" : "ControlOrMeta+z");
    await expect(page.locator(editor)).toHaveValue(before);
  });
}

test("composition key flags bypass commands before the composing model renders", async ({ page }) => {
  await open(page);
  const before = await value(page);
  const prevented = await page.$eval(editor, (node) => {
    return [{ isComposing: true }, { keyCode: 229 }].map(flags => {
      const event = new KeyboardEvent("keydown", {
        key: "Enter", bubbles: true, cancelable: true, ...flags,
      });
      node.dispatchEvent(event);
      return event.defaultPrevented;
    });
  });
  expect(prevented).toEqual([false, false]);
  await expect(page.locator(editor)).toHaveValue(before);
});
