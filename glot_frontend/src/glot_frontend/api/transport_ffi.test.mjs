import assert from "node:assert/strict";
import test from "node:test";
import {
  cancelNavigationRequests,
  cancelRunRequests,
  send,
} from "./transport_ffi.mjs";

function response({
  body = '{"data":null}',
  contentType = "application/json; charset=utf-8",
  status = 200,
} = {}) {
  return {
    status,
    headers: {
      get(name) {
        assert.equal(name, "content-type");
        return contentType;
      },
    },
    async text() {
      return body;
    },
  };
}

test("send posts the mux envelope with explicit same-origin credentials", async () => {
  let request;
  const result = new Promise((resolve) => {
    send(
      "/api/mux",
      '{"action":"fixture"}',
      "persistent",
      (...values) => resolve(values),
      async (endpoint, options) => {
        request = { endpoint, options };
        return response({ status: 201, body: '{"data":"ok"}' });
      },
    );
  });

  assert.deepEqual(await result, [
    "response",
    201,
    "application/json; charset=utf-8",
    '{"data":"ok"}',
  ]);
  assert.equal(request.endpoint, "/api/mux");
  assert.equal(request.options.method, "POST");
  assert.deepEqual(request.options.headers, {
    "content-type": "application/json",
  });
  assert.equal(request.options.credentials, "same-origin");
  assert.equal(request.options.body, '{"action":"fixture"}');
  assert.equal(request.options.signal.aborted, false);
});

test("navigation cancellation aborts owned reads without dispatching failure", async () => {
  let signal;
  let dispatched = false;
  let rejected;
  const pending = new Promise((_resolve, reject) => {
    rejected = reject;
  });
  send(
    "/api/mux",
    "{}",
    "navigation",
    () => {
      dispatched = true;
    },
    async (_endpoint, options) => {
      signal = options.signal;
      signal.addEventListener("abort", () => rejected(new Error("aborted")));
      return pending;
    },
  );

  cancelNavigationRequests();
  await Promise.resolve();
  await Promise.resolve();

  assert.equal(signal.aborted, true);
  assert.equal(dispatched, false);
});

test("navigation cancellation never aborts persistent requests", async () => {
  let resolveFetch;
  const pending = new Promise((resolve) => {
    resolveFetch = resolve;
  });
  const result = new Promise((resolve) => {
    send(
      "/api/mux",
      "{}",
      "persistent",
      (...values) => resolve(values),
      async () => pending,
    );
  });

  cancelNavigationRequests();
  resolveFetch(response());

  assert.deepEqual(await result, [
    "response",
    200,
    "application/json; charset=utf-8",
    '{"data":null}',
  ]);
});

test("network and body failures remain distinct", async () => {
  const network = new Promise((resolve) => {
    send("/api/mux", "{}", "persistent", (...values) => resolve(values), async () => {
      throw new Error("offline");
    });
  });
  const body = new Promise((resolve) => {
    send("/api/mux", "{}", "persistent", (...values) => resolve(values), async () => ({
      ...response(),
      async text() {
        throw new Error("stream failed");
      },
    }));
  });

  assert.deepEqual(await network, ["network", 0, "", ""]);
  assert.deepEqual(await body, ["body", 0, "", ""]);
});

test("run cancellation only aborts run requests", async () => {
  let runSignal;
  let navigationSignal;
  const pending = new Promise(() => {});

  send("/api/mux", "{}", "run", () => {}, async (_endpoint, options) => {
    runSignal = options.signal;
    return pending;
  });
  send("/api/mux", "{}", "navigation", () => {}, async (_endpoint, options) => {
    navigationSignal = options.signal;
    return pending;
  });

  cancelRunRequests();

  assert.equal(runSignal.aborted, true);
  assert.equal(navigationSignal.aborted, false);
  cancelNavigationRequests();
});
