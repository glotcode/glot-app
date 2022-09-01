import init from "../wasm/glot.js";
import { snippetPage } from "../wasm/glot";
import { Polyester } from "polyester";
import { defaultDebugConfig } from "polyester/src/logger";

(async () => {
  await init("/wasm/glot_bg.wasm");

  const polyester = new Polyester(snippetPage(), {
    loggerConfig: defaultDebugConfig(),
  });

  polyester.init();
})();

class AceEditorElement extends HTMLElement {
  private editor: any;
  private observer: MutationObserver;
  public value: string = "";

  constructor() {
    super();

    const stylesheetElem = this.getStylesheetElement();
    const editorElem = this.createEditorElement();

    const shadow = this.attachShadow({ mode: "closed" });

    if (stylesheetElem !== null) {
      shadow.appendChild(stylesheetElem);
    }

    shadow.appendChild(editorElem);

    // @ts-ignore
    this.editor = ace.edit(editorElem);
    this.editor.renderer.attachToShadowRoot();

    this.setContent(this.textContent || "");

    this.editor.getSession().on("change", () => {
      this.value = this.editor.getValue();

      const event = new Event("change", {
        bubbles: true,
      });

      this.dispatchEvent(event);
    });

    this.observer = new MutationObserver(() => {
      this.setContent(this.textContent || "");
    });
  }

  public connectedCallback() {
    if (this.isConnected) {
      this.observer.observe(this, {
        characterData: true,
        subtree: true,
      });
    }
  }

  public disconnectedCallback() {
    this.observer.disconnect();
  }

  private setContent(content: string) {
    if (content !== this.value) {
      this.value = content;
    }

    if (this.editor.getValue() !== content) {
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

    const height = this.getAttribute("height");
    if (height !== null) {
      editorElem.style.height = height;
    }

    return editorElem;
  }
}

customElements.define("poly-ace-editor", AceEditorElement);
