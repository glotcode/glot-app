import {
  readThemeCookie,
  serializeThemeCookie,
  type ThemePreference,
} from "./glot-theme-preference.mjs";

function readPreference(): ThemePreference {
  return readThemeCookie(document.cookie);
}

function savePreference(preference: ThemePreference) {
  document.cookie = serializeThemeCookie(
    preference,
    window.location.protocol === "https:",
  );
}

export function applyThemePreference() {
  const preference = readPreference();
  if (preference === "system") {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.dataset.theme = preference;
  }
}

class GlotThemePicker extends HTMLElement {
  private readonly select: HTMLSelectElement;

  constructor() {
    super();

    const shadow = this.attachShadow({ mode: "open" });
    const style = document.createElement("style");
    style.textContent = `
      :host {
        display: inline-flex;
        align-items: center;
        font: inherit;
      }

      label {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        color: var(--theme-text-muted);
      }

      span {
        font-size: 0.68rem;
        font-weight: 700;
        letter-spacing: 0.1em;
        text-transform: uppercase;
      }

      select {
        min-height: 2.75rem;
        padding: 0.25rem 1.7rem 0.25rem 0.5rem;
        border: 1px solid var(--theme-border);
        border-radius: 0;
        background: var(--theme-surface);
        color: var(--theme-text);
        cursor: pointer;
        font: inherit;
        font-size: 0.72rem;
      }

      select:focus-visible {
        outline: 3px solid var(--color-focus);
        outline-offset: 3px;
      }

      @media (forced-colors: active) {
        select:focus-visible {
          outline-color: Highlight;
        }
      }

      @media (max-width: 560px) {
        span {
          position: absolute;
          width: 1px;
          height: 1px;
          padding: 0;
          margin: -1px;
          overflow: hidden;
          clip: rect(0, 0, 0, 0);
          white-space: nowrap;
          border: 0;
        }
      }
    `;

    const label = document.createElement("label");
    const labelText = document.createElement("span");
    labelText.textContent = "Theme";

    this.select = document.createElement("select");
    this.select.setAttribute("aria-label", "Color theme");
    for (const [value, text] of [
      ["system", "System"],
      ["white", "White"],
      ["light", "Solarized Light"],
      ["dark", "Solarized Dark"],
    ] as const) {
      const option = document.createElement("option");
      option.value = value;
      option.textContent = text;
      this.select.append(option);
    }

    this.select.addEventListener("change", () => {
      savePreference(this.select.value as ThemePreference);
      window.location.reload();
    });
    label.append(labelText, this.select);
    shadow.append(style, label);
  }

  connectedCallback() {
    this.select.value = readPreference();
  }
}

export function initializeTheme() {
  applyThemePreference();

  if (!customElements.get("glot-theme-picker")) {
    customElements.define("glot-theme-picker", GlotThemePicker);
  }
}
