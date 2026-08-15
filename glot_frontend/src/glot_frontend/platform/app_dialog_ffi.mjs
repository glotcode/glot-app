function bindBackdropClose(dialog) {
  if (dialog.dataset.appDialogBound === "true") {
    return;
  }

  dialog.addEventListener("mousedown", (event) => {
    const rect = dialog.getBoundingClientRect();
    const pressedInside =
      rect.left <= event.clientX &&
      event.clientX <= rect.right &&
      rect.top <= event.clientY &&
      event.clientY <= rect.bottom;

    if (!pressedInside) {
      dialog.close();
    }
  });

  dialog.dataset.appDialogBound = "true";
}

export function openDialog(id) {
  openDialogNowOrOnNextFrame(id);
}

export function openDialogNextFrame(id) {
  window.requestAnimationFrame(() => {
    openDialogNowOrOnNextFrame(id);
  });
}

function openDialogNowOrOnNextFrame(id, retried = false) {
  const dialog = document.getElementById(id);

  if (!(dialog instanceof HTMLDialogElement)) {
    if (!retried) {
      window.requestAnimationFrame(() => {
        openDialogNowOrOnNextFrame(id, true);
      });
    }
    return;
  }

  bindBackdropClose(dialog);

  if (dialog.open) {
    return;
  }

  dialog.showModal();
}

export function closeDialog(id) {
  const dialog = document.getElementById(id);

  if (!(dialog instanceof HTMLDialogElement) || !dialog.open) {
    return;
  }

  dialog.close();
}

export function focusElement(id) {
  const element = document.getElementById(id);

  if (!(element instanceof HTMLElement)) {
    return;
  }

  element.focus();
}

export function blurElement(id) {
  window.requestAnimationFrame(() => {
    const element = document.getElementById(id);

    if (!(element instanceof HTMLElement)) {
      return;
    }

    element.blur();
  });
}
