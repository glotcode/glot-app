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

async function nativeRange(page: Page) {
  return page.$eval(editor, (node) => {
    const field = node as HTMLTextAreaElement;
    return [field.selectionStart, field.selectionEnd, field.selectionDirection];
  });
}

test("Vim visual highlighting includes both endpoints through swaps and reselection", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 1);
  await page.keyboard.press("v");
  await expect.poll(() => nativeRange(page)).toEqual([1, 2, "forward"]);
  await page.keyboard.press("l");
  await expect.poll(() => nativeRange(page)).toEqual([1, 3, "forward"]);
  await page.keyboard.press("o");
  await expect.poll(() => nativeRange(page)).toEqual([1, 3, "backward"]);
  await page.keyboard.press("h");
  await expect.poll(() => nativeRange(page)).toEqual([0, 3, "backward"]);
  await page.keyboard.press("Escape");
  await expectCaret(page, 0);
  await page.keyboard.press("g");
  await page.keyboard.press("v");
  await expect.poll(() => nativeRange(page)).toEqual([0, 3, "backward"]);
  const before = await value(page);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue(before.slice(3));
});

test("Vim linewise highlighting and mode switches retain the logical cursor", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  const secondStart = before.indexOf("\n") + 1;
  const thirdStart = before.indexOf("\n", secondStart) + 1;
  await page.keyboard.press("V");
  await expect.poll(() => nativeRange(page)).toEqual([0, secondStart, "forward"]);
  await page.keyboard.press("j");
  await expect.poll(() => nativeRange(page)).toEqual([0, thirdStart, "forward"]);
  await page.keyboard.press("v");
  await expect.poll(() => nativeRange(page)).toEqual([0, secondStart + 1, "forward"]);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue(before.slice(secondStart + 1));
});

test("Vim pointer movement exits visual mode without changing text", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("v");
  await page.keyboard.press("l");
  await expect.poll(() => nativeRange(page)).toEqual([0, 2, "forward"]);
  await setCaret(page, 5);
  await expect(page.locator("#code-editor-status")).toContainText("NORMAL");
  await page.keyboard.press("x");
  await expect(page.locator(editor)).toHaveValue(before.slice(0, 5) + before.slice(6));
});

test("Vim block selection highlights separate rows and deletes in one undo step", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("Control+v");
  await page.keyboard.press("j");
  await page.keyboard.press("l");
  await expect(page.locator(".code-editor__vim-block")).toHaveCount(2);
  const rectangles = await page.locator(".code-editor__vim-block").evaluateAll((nodes) =>
    nodes.map((node) => ({ left: (node as HTMLElement).style.left, width: (node as HTMLElement).style.width })),
  );
  expect(rectangles[0]).toEqual(rectangles[1]);
  await page.keyboard.press("d");
  const lines = before.split("\n");
  lines[0] = lines[0].slice(2);
  lines[1] = lines[1].slice(2);
  await expect(page.locator(editor)).toHaveValue(lines.join("\n"));
  await expect(page.locator(".code-editor__vim-block")).toHaveCount(0);
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue(before);
  await expectCaret(page, 0);
});

test("Vim block dollar follows each row end through vertical motion", async ({ page }) => {
  await open(page, "vim");
  await page.keyboard.press("i");
  await page.locator(editor).fill("abcd\nefghijkl\nxyzxyz");
  await page.keyboard.press("Escape");
  await setCaret(page, 1);
  await page.keyboard.press("Control+v");
  await page.keyboard.press("$");
  await page.keyboard.press("j");
  await page.keyboard.press("j");
  await expect(page.locator(".code-editor__vim-block")).toHaveCount(3);
  await expect.poll(() => page.locator(".code-editor__vim-block").evaluateAll(nodes =>
    nodes.map(node => {
      const style = (node as HTMLElement).style;
      return Math.round(parseFloat(style.width) / parseFloat(style.left));
    }),
  )).toEqual([3, 7, 5]);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue("a\ne\nx");
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue("abcd\nefghijkl\nxyzxyz");
});

for (const operation of ["I", "A", "c"]) {
  test(`Vim block ${operation} replicates native insertion and groups undo`, async ({ page }) => {
    await open(page, "vim");
    await setCaret(page, 0);
    const before = await value(page);
    await page.keyboard.press("Control+v");
    await page.keyboard.press("j");
    await page.keyboard.press("l");
    await page.keyboard.press(operation);
    await page.keyboard.type("XY");
    await page.keyboard.press("Escape");
    const lines = before.split("\n");
    for (let i = 0; i < 2; i++) {
      lines[i] = operation === "I" ? "XY" + lines[i] : operation === "A"
        ? lines[i].slice(0, 2) + "XY" + lines[i].slice(2) : "XY" + lines[i].slice(2);
    }
    await expect(page.locator(editor)).toHaveValue(lines.join("\n"));
    await page.keyboard.press("u");
    await expect(page.locator(editor)).toHaveValue(before);
    await expectCaret(page, 0);
  });
}

test("Vim dot repeats inserted text as its own undo step", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("i");
  await page.keyboard.type("XY");
  await page.keyboard.press("Escape");
  await page.keyboard.press("l");
  await page.keyboard.press(".");
  await expect(page.locator(editor)).toHaveValue("XYXY" + before);
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue("XY" + before);
});


for (const operation of ["D", "C"]) {
  test(`Vim visual ${operation} acts on the selected lines`, async ({ page }) => {
    await open(page, "vim");
    await setCaret(page, 1);
    const before = await value(page);
    await page.keyboard.press("v");
    await page.keyboard.press("j");
    await page.keyboard.press(operation);
    if (operation === "C") {
      await page.keyboard.type("X");
      await page.keyboard.press("Escape");
    }
    const remainder = before.split("\n").slice(2).join("\n");
    await expect(page.locator(editor)).toHaveValue(operation === "C" ? "X\n" + remainder : remainder);
    await expect(page.locator("#code-editor-status")).toContainText("NORMAL");
  });
}

test("Vim block O exchanges horizontal corners without changing the rectangle", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("Control+v");
  await page.keyboard.press("j");
  await page.keyboard.press("l");
  await page.keyboard.press("O");
  await expect(page.locator(".code-editor__vim-block")).toHaveCount(2);
  await expect.poll(() => nativeRange(page)).toEqual([before.indexOf("\n") + 1, before.indexOf("\n") + 1, "forward"]);
  await page.keyboard.press("d");
  const lines = before.split("\n");
  lines[0] = lines[0].slice(2);
  lines[1] = lines[1].slice(2);
  await expect(page.locator(editor)).toHaveValue(lines.join("\n"));
});


test("Vim dot repeats a visual deletion with its original width", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("v");
  await page.keyboard.press("l");
  await page.keyboard.press("d");
  await page.keyboard.press("l");
  await page.keyboard.press(".");
  await expect(page.locator(editor)).toHaveValue(before.slice(2, 3) + before.slice(5));
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue(before.slice(2));
});

test("Vim dot repeats a block change across the same number of rows", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("Control+v");
  await page.keyboard.press("j");
  await page.keyboard.press("l");
  await page.keyboard.press("c");
  await page.keyboard.type("X");
  await page.keyboard.press("Escape");
  await page.keyboard.press("j");
  await page.keyboard.press("j");
  await page.keyboard.press(".");
  const lines = before.split("\n");
  for (let i = 0; i < 4; i++) lines[i] = "X" + lines[i].slice(2);
  await expect(page.locator(editor)).toHaveValue(lines.join("\n"));
  await expect(page.locator(".code-editor__vim-block")).toHaveCount(0);
  await page.keyboard.press("u");
  const firstChange = before.split("\n");
  for (let i = 0; i < 2; i++) firstChange[i] = "X" + firstChange[i].slice(2);
  await expect(page.locator(editor)).toHaveValue(firstChange.join("\n"));
});


test("Vim visual Ex substitution prefills its range and is one undo step", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("i");
  await page.keyboard.type("one\none\none\n");
  await page.keyboard.press("Escape");
  await setCaret(page, 0);
  for (const key of ["V", "j", ":"]) await page.keyboard.press(key);
  const field = page.locator("#code-editor-prompt-field");
  await expect(field).toHaveValue("'<,'>");
  await field.fill("'<,'>s/one/X/g");
  await field.press("Enter");
  await expect(page.locator(editor)).toBeFocused();
  await expect(page.locator(editor)).toHaveValue("X\nX\none\n" + before);
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue("one\none\none\n" + before);
});

test("Vim sentence objects extend through whitespace and undo deletion", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("i");
  await page.keyboard.type("One. Two. Three.\n");
  await page.keyboard.press("Escape");
  await setCaret(page, 0);
  for (const key of ["v", "i", "s"]) await page.keyboard.press(key);
  await expect.poll(() => nativeRange(page)).toEqual([0, 4, "forward"]);
  for (const key of ["i", "s"]) await page.keyboard.press(key);
  await expect.poll(() => nativeRange(page)).toEqual([0, 5, "forward"]);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue("Two. Three.\n" + before);
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue("One. Two. Three.\n" + before);
});

test("Vim repeated tag objects expand through nested elements", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("i");
  await page.keyboard.type("<p>hello <b>world</b></p>\n");
  await page.keyboard.press("Escape");
  await setCaret(page, 11);
  for (const key of ["v", "i", "t"]) await page.keyboard.press(key);
  await expect.poll(() => nativeRange(page)).toEqual([12, 17, "forward"]);
  for (const key of ["i", "t"]) await page.keyboard.press(key);
  await expect.poll(() => nativeRange(page)).toEqual([9, 21, "forward"]);
  for (const key of ["i", "t"]) await page.keyboard.press(key);
  await expect.poll(() => nativeRange(page)).toEqual([3, 21, "forward"]);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue("<p></p>\n" + before);
});

test("Vim repeated word objects extend the visible selection", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("i");
  await page.keyboard.type("one two three ");
  await page.keyboard.press("Escape");
  await setCaret(page, 0);
  for (const key of ["v", "i", "w", "i", "w"]) await page.keyboard.press(key);
  await expect.poll(() => nativeRange(page)).toEqual([0, 4, "forward"]);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue("two three " + before);
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue("one two three " + before);
});

test("Vim counted insertion repeats native text and undoes in one step", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("3");
  await page.keyboard.press("i");
  await page.keyboard.type("XY");
  await page.keyboard.press("Escape");
  await expect(page.locator(editor)).toHaveValue("XYXYXY" + before);
  await expectCaret(page, 5);
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue(before);
});

test("Vim replace mode overwrites text and Backspace restores it", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 1);
  const before = await value(page);
  await page.keyboard.press("R");
  await page.keyboard.type("XY");
  await expect(page.locator(editor)).toHaveValue(before.slice(0, 1) + "XY" + before.slice(3));
  await page.keyboard.press("Backspace");
  await page.keyboard.press("Escape");
  await expect(page.locator(editor)).toHaveValue(before.slice(0, 1) + "X" + before.slice(2));
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue(before);
});


async function vimSearch(page: Page, pattern: string) {
  const field = page.locator("#code-editor-prompt-field");
  await expect(field).toBeFocused();
  await field.fill(pattern);
  await field.press("Enter");
  await expect(page.locator(editor)).toBeFocused();
}

test("Vim keyword-boundary search uses the exact matching occurrence", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("i");
  await page.keyboard.type("one someone one\n");
  await page.keyboard.press("Escape");
  await setCaret(page, 0);
  await page.keyboard.press("/");
  await vimSearch(page, "\\<one\\>");
  await expectCaret(page, 12);
  await page.keyboard.press("x");
  await expect(page.locator(editor)).toHaveValue("one someone ne\n" + before);
});

test("Vim search places the cursor at the match start", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  const target = before.indexOf("function");
  await page.keyboard.press("/");
  await vimSearch(page, "function");
  await expectCaret(page, target);
  await page.keyboard.press("x");
  await expect(page.locator(editor)).toHaveValue(before.slice(0, target) + before.slice(target + 1));
});

test("Vim visual search keeps the anchor and inclusive highlight", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  const target = before.indexOf("function");
  await page.keyboard.press("v");
  await page.keyboard.press("/");
  await vimSearch(page, "function");
  await expect.poll(() => nativeRange(page)).toEqual([0, target + 1, "forward"]);
  await page.keyboard.press("d");
  await expect(page.locator(editor)).toHaveValue(before.slice(target + 1));
});

test("Vim operator search waits for the prompt and remains undoable", async ({ page }) => {
  await open(page, "vim");
  await setCaret(page, 0);
  const before = await value(page);
  await page.keyboard.press("d");
  await page.keyboard.press("/");
  await vimSearch(page, "function");
  await expect(page.locator(editor)).toHaveValue(before.slice(before.indexOf("function")));
  await page.keyboard.press("u");
  await expect(page.locator(editor)).toHaveValue(before);
});
