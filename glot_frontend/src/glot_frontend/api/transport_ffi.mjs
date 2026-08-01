const navigationControllers = new Set();
const runControllers = new Set();

export function send(
  endpoint,
  body,
  cancellationGroup,
  callback,
  browserFetch = globalThis.fetch,
) {
  const controller = new AbortController();
  if (cancellationGroup === "navigation") navigationControllers.add(controller);
  if (cancellationGroup === "run") runControllers.add(controller);

  browserFetch(endpoint, {
    method: "POST",
    headers: { "content-type": "application/json" },
    credentials: "same-origin",
    body,
    signal: controller.signal,
  })
    .then(async (response) => {
      let responseBody;
      try {
        responseBody = await response.text();
      } catch {
        if (!controller.signal.aborted) callback("body", 0, "", "");
        return;
      }

      if (!controller.signal.aborted) {
        callback(
          "response",
          response.status,
          response.headers.get("content-type") ?? "",
          responseBody,
        );
      }
    })
    .catch(() => {
      if (!controller.signal.aborted) callback("network", 0, "", "");
    })
    .finally(() => {
      navigationControllers.delete(controller);
      runControllers.delete(controller);
    });
}

export function cancelNavigationRequests() {
  for (const controller of navigationControllers) controller.abort();
  for (const controller of runControllers) controller.abort();
  navigationControllers.clear();
  runControllers.clear();
}

export function cancelRunRequests() {
  for (const controller of runControllers) controller.abort();
  runControllers.clear();
}
