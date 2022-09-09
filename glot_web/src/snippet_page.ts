import init from "../wasm/glot.js";
import { snippetPage } from "../wasm/glot";
import { BrowserWindow, Polyester } from "polyester";
import { defaultDebugConfig } from "polyester/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const browserWindow = new BrowserWindow();
  const windowSize = browserWindow.getSize();

  const polyester = new Polyester(snippetPage(windowSize), {
    loggerConfig: defaultDebugConfig(),
  });

  polyester.init();
})();

class AceEditorElement extends HTMLElement {
  private editor: any;
  private contentObserver: MutationObserver;
  private focusListenerController: AbortController;
  private editorElem: HTMLElement;
  public value: string = "";

  constructor() {
    super();

    const stylesheetElem = this.getStylesheetElement();
    this.editorElem = this.createEditorElement();

    const shadow = this.attachShadow({ mode: "closed" });

    if (stylesheetElem !== null) {
      shadow.appendChild(stylesheetElem);
    }

    shadow.appendChild(this.editorElem);

    // @ts-ignore
    this.editor = ace.edit(this.editorElem);
    this.editor.renderer.attachToShadowRoot();

    this.setContent(this.textContent || "");

    this.editor.getSession().on("change", () => {
      this.value = this.editor.getValue();

      const event = new Event("change", {
        bubbles: true,
      });

      this.dispatchEvent(event);
    });

    this.contentObserver = new MutationObserver(() => {
      this.setContent(this.textContent || "");
    });

    this.focusListenerController = new AbortController();
  }

  public connectedCallback() {
    if (this.isConnected) {
      this.startContentObserver();
      this.startListenForFocusEvents();
    }
  }

  public disconnectedCallback() {
    this.stopContentObserver();
    this.stopListenForFocusEvents();
  }

  private setContent(content: string) {
    if (content !== this.value) {
      this.value = content;
      this.editor.setValue(content, 1);
    }
  }

  private getStylesheetElement(): Node | null {
    const stylesheetId = this.getAttribute("stylesheet-id");

    if (stylesheetId === null) {
      return null;
    }

    const elem = document.getElementById(stylesheetId);
    if (elem === null) {
      return null;
    }

    return elem.cloneNode();
  }

  private createEditorElement(): HTMLDivElement {
    const editorElem = document.createElement("div");

    // Copy classes from the host element
    editorElem.classList.value = this.classList.value;

    return editorElem;
  }

  static get observedAttributes() {
    return ["height", "keyboard-handler", "theme"];
  }

  public attributeChangedCallback(
    name: string,
    _oldValue: string,
    newValue: string
  ) {
    switch (name) {
      case "height":
        this.editorElem.style.height = newValue;
        break;

      case "keyboard-handler":
        this.editor.setKeyboardHandler(newValue);
        break;

      case "theme":
        this.editor.setTheme(newValue);
        break;
    }
  }

  private startContentObserver() {
    this.contentObserver.observe(this, {
      characterData: true,
      subtree: true,
      childList: true,
    });
  }

  private stopContentObserver() {
    this.contentObserver.disconnect();
  }

  private startListenForFocusEvents() {
    this.addEventListener(
      "focus",
      (_event) => {
        this.editor.focus();
      },
      {
        signal: this.focusListenerController.signal,
        passive: true,
      }
    );
  }

  private stopListenForFocusEvents() {
    this.focusListenerController.abort();
  }
}

customElements.define("poly-ace-editor", AceEditorElement);
