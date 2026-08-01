import assert from "node:assert/strict";
import { afterEach, test } from "node:test";
import { take } from "./ssr_data_ffi.mjs";

afterEach(() => {
  delete globalThis.document;
});

test("take is safe outside a browser", () => {
  assert.equal(take("glot-ssr-data"), "");
});

test("take returns the SSR payload and removes its data block", () => {
  let removed = false;
  const data = {
    textContent: '{"source":"large payload"}',
    remove() {
      removed = true;
    },
  };
  globalThis.document = {
    getElementById(id) {
      assert.equal(id, "glot-ssr-data");
      return removed ? null : data;
    },
  };

  assert.equal(take("glot-ssr-data"), '{"source":"large payload"}');
  assert.equal(removed, true);
  assert.equal(take("glot-ssr-data"), "");
});

test("take removes an empty SSR data block", () => {
  let removed = false;
  globalThis.document = {
    getElementById() {
      return {
        textContent: "",
        remove() {
          removed = true;
        },
      };
    },
  };

  assert.equal(take("glot-ssr-data"), "");
  assert.equal(removed, true);
});
