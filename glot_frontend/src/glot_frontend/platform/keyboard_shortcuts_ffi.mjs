let shortcutsBound = false;

function shouldIgnoreTarget(target) {
  if (
    !(target instanceof HTMLElement) ||
    target.isContentEditable
  ) {
    return false;
  }

  const tag = target.tagName;

  return (
    tag === "INPUT" ||
    tag === "TEXTAREA" ||
    tag === "SELECT"
  );
}

function shouldTriggerEditorRun(target) {
  if (!(target instanceof HTMLElement)) {
    return true;
  }

  // Ctrl/Cmd-Enter runs the snippet from inside the code editor too.
  if (target.closest(".code-editor")) {
    return true;
  }

  if (target.isContentEditable) {
    return false;
  }

  const tag = target.tagName;

  return !(tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT");
}

export function bindShortcuts(onQuickActions, onEditorRun) {
  if (shortcutsBound || typeof document === "undefined") {
    return;
  }

  document.addEventListener("keydown", (event) => {
    if (event.defaultPrevented || event.isComposing || event.keyCode === 229) {
      return;
    }

    if (
      event.key.toLowerCase() === "k" &&
      !event.altKey &&
      !event.shiftKey &&
      (event.metaKey || event.ctrlKey) &&
      !shouldIgnoreTarget(event.target)
    ) {
      event.preventDefault();
      onQuickActions();
      return;
    }

    if (
      event.key !== "Enter" ||
      event.altKey ||
      event.shiftKey ||
      !(event.metaKey || event.ctrlKey) ||
      !shouldTriggerEditorRun(event.target)
    ) {
      return;
    }

    event.preventDefault();
    onEditorRun();
  });

  shortcutsBound = true;
}
