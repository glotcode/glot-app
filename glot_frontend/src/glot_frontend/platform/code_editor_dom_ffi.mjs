// Browser interop for the native code editor.
//
// Everything here is mechanical: read geometry, write a value, move a caret,
// scroll. Command semantics, history, and keymaps live in Gleam.

const observers = new Map();
const pendingScrolls = new WeakMap();

function element(id) {
  return document.getElementById(id);
}

export function setIdentity(id, key, generation) {
  const node = element(id);
  if (!node) return;
  node.dataset.session = key;
  node.dataset.generation = String(generation);
}

export function setValue(id, value, anchor, head) {
  const node = element(id);
  if (!node) return;

  pendingScrolls.get(node)?.();

  // Rewriting the value during composition would cancel the IME, and rewriting
  // an unchanged value would reset the scroll position for nothing.
  if (node.value !== value) {
    node.value = value;
  }

  setSelection(id, anchor, head);
}

export function setSelection(id, anchor, head) {
  const node = element(id);
  if (!node) return;
  const start = Math.min(anchor, head);
  const end = Math.max(anchor, head);
  const direction = head < anchor ? "backward" : "forward";
  if (node.selectionStart === start && node.selectionEnd === end &&
      (start === end || node.selectionDirection === direction)) return;
  try {
    node.setSelectionRange(start, end, direction);
  } catch {
    // Detached or hidden inputs can reject selection changes.
  }
}

export function restoreScroll(id, top, left) {
  const node = element(id);
  if (!node) return;
  pendingScrolls.get(node)?.();
  const apply = () => { node.scrollTop = top; node.scrollLeft = left; };
  apply();

  // Firefox can scroll the caret during the next layout after setSelectionRange.
  // Reapply after that layout, unless another write or user interaction has
  // superseded this restoration. Never defer a document or selection write.
  const value = node.value;
  const start = node.selectionStart;
  const end = node.selectionEnd;
  const interactions = ["keydown", "input", "pointerdown", "wheel", "touchstart"];
  let frame;
  const cancel = () => {
    cancelAnimationFrame(frame);
    for (const type of interactions) document.removeEventListener(type, cancel, true);
    pendingScrolls.delete(node);
  };
  for (const type of interactions) document.addEventListener(type, cancel, true);
  pendingScrolls.set(node, cancel);
  frame = requestAnimationFrame(() => {
    frame = requestAnimationFrame(() => {
      if (node.isConnected && node.value === value &&
          node.selectionStart === start && node.selectionEnd === end) apply();
      cancel();
    });
  });
}

function lineHeightOf(node) {
  const parsed = Number.parseInt(node.dataset.lineHeight ?? "", 10);
  if (Number.isSafeInteger(parsed) && parsed > 0) return parsed;

  const computed = Number.parseFloat(getComputedStyle(node).lineHeight);
  return Number.isFinite(computed) && computed > 0 ? computed : 26;
}

export function scrollToLine(id, line, intent) {
  const node = element(id);
  if (!node) return;

  const lineHeight = lineHeightOf(node);
  const top = line * lineHeight;
  const height = node.clientHeight;

  switch (intent) {
    case "top":
      node.scrollTop = top;
      return;
    case "center":
      node.scrollTop = Math.max(0, top - height / 2 + lineHeight / 2);
      return;
    case "bottom":
      node.scrollTop = Math.max(0, top - height + lineHeight);
      return;
    default: {
      if (top < node.scrollTop) {
        node.scrollTop = top;
      } else if (top + lineHeight > node.scrollTop + height) {
        node.scrollTop = top + lineHeight - height;
      }
    }
  }
}

export function scrollByLines(id, lines) {
  const node = element(id);
  if (!node) return;
  node.scrollTop = Math.max(0, node.scrollTop + lines * lineHeightOf(node));
}

export function focusElement(id) {
  const node = element(id);
  if (!node) return;
  node.focus({ preventScroll: true });
}

export function writeClipboard(value) {
  if (!value) return;
  if (navigator.clipboard?.writeText) {
    void navigator.clipboard.writeText(value).catch(() => {
      // Clipboard permission can be refused; the editor keeps its own kill ring
      // and register, so nothing is lost inside the page.
    });
  }
}

function measure(node, callback) {
  const style = getComputedStyle(node);
  const lineHeight = Math.round(Number.parseFloat(style.lineHeight) || 26);

  const probe = document.createElement("span");
  probe.textContent = "0".repeat(10);
  probe.style.font = style.font;
  probe.style.position = "absolute";
  probe.style.visibility = "hidden";
  probe.style.whiteSpace = "pre";
  document.body.append(probe);
  const characterWidth = Math.round(probe.getBoundingClientRect().width / 10);
  probe.remove();

  callback(
    Math.max(1, lineHeight),
    Math.round(node.clientHeight),
    Math.round(node.clientWidth),
    Math.max(1, characterWidth),
  );
}

export function observe(id, callback) {
  disconnect(id);

  const node = element(id);
  if (!node) return;

  measure(node, callback);

  if (typeof ResizeObserver === "undefined") return;

  const observer = new ResizeObserver(() => measure(node, callback));
  observer.observe(node);
  observers.set(id, observer);

  if (document.fonts?.ready) {
    void document.fonts.ready.then(() => {
      if (observers.get(id) === observer) measure(node, callback);
    });
  }
}

export function disconnect(id) {
  const observer = observers.get(id);
  if (!observer) return;
  observer.disconnect();
  observers.delete(id);
}
