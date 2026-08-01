import { EditorState, Compartment, type Extension } from "@codemirror/state";
import { EditorView, keymap } from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { lineNumbers, highlightActiveLineGutter } from "@codemirror/view";
import { highlightActiveLine, drawSelection, dropCursor } from "@codemirror/view";
import { defaultHighlightStyle, HighlightStyle, indentOnInput, syntaxHighlighting } from "@codemirror/language";
import { bracketMatching } from "@codemirror/language";
import { highlightSelectionMatches, searchKeymap } from "@codemirror/search";
import { rectangularSelection } from "@codemirror/view";
import { indentWithTab } from "@codemirror/commands";
import { StreamLanguage } from "@codemirror/language"
import { tags } from "@lezer/highlight";
import {
  documentUpdate,
  initialDocumentValue,
  shouldApplyDocumentValue
} from "./glot-codemirror-document.mjs";

const editorTheme = EditorView.theme({
  "&": {
    height: "100%",
    color: "var(--theme-text-strong)",
    backgroundColor: "var(--theme-page)"
  },
  ".cm-content": {
    caretColor: "var(--color-accent)",
    fontFamily: '"Lucida Console", Monaco, "Courier New", monospace',
    fontSize: "16px",
    lineHeight: "1.6",
    textShadow: "0 0 4px var(--theme-code-shadow)"
  },
  ".cm-cursor, .cm-dropCursor": {
    borderLeftColor: "var(--color-accent)"
  },
  ".cm-selectionBackground, ::selection": {
    backgroundColor: "var(--color-accent-selection) !important"
  },
  ".cm-gutters": {
    backgroundColor: "var(--theme-surface-muted)",
    color: "var(--theme-text-subtle)",
    borderRight: "1px solid var(--theme-border)"
  },
  ".cm-activeLineGutter": {
    backgroundColor: "var(--color-accent-selection-muted)",
    color: "var(--theme-text-muted)"
  },
  ".cm-activeLine": {
    backgroundColor: "var(--color-accent-line)"
  },
  ".cm-lineNumbers .cm-gutterElement": {
    paddingLeft: "10px",
    paddingRight: "10px"
  },
  ".cm-scroller": {
    fontFamily: '"Lucida Console", Monaco, "Courier New", monospace'
  },
  ".cm-tooltip": {
    border: "1px solid var(--theme-border)",
    backgroundColor: "var(--theme-surface)",
    color: "var(--theme-text-strong)"
  },
  ".cm-panels": {
    backgroundColor: "var(--theme-surface-muted)",
    color: "var(--theme-text-strong)"
  },
  ".cm-searchMatch": {
    backgroundColor: "var(--color-warning-emphasis)",
    outline: "1px solid var(--color-diagnostic)"
  }
});

const editorHighlightStyle = HighlightStyle.define([
  { tag: [tags.keyword, tags.modifier], color: "var(--syntax-keyword)", fontWeight: "bold" },
  { tag: [tags.string, tags.special(tags.string)], color: "var(--syntax-string)" },
  { tag: [tags.number, tags.bool, tags.null], color: "var(--syntax-number)" },
  { tag: [tags.comment], color: "var(--theme-text-subtle)", fontStyle: "italic" },
  { tag: [tags.function(tags.variableName), tags.labelName], color: "var(--syntax-function)" },
  { tag: [tags.typeName, tags.className], color: "var(--syntax-type)" },
  { tag: [tags.variableName, tags.propertyName], color: "var(--theme-text-muted)" },
  { tag: [tags.operator, tags.punctuation, tags.separator], color: "var(--theme-text-subtle)" }
]);

// Minimal "basic setup" (avoids depending on codemirror meta-package)
const basicSetup: Extension = [
  lineNumbers(),
  highlightActiveLineGutter(),
  history(),
  drawSelection(),
  dropCursor(),
  indentOnInput(),
  bracketMatching(),
  rectangularSelection(),
  highlightActiveLine(),
  highlightSelectionMatches(),
  editorTheme,
  syntaxHighlighting(defaultHighlightStyle),
  syntaxHighlighting(editorHighlightStyle),
  keymap.of([
    ...defaultKeymap,
    ...searchKeymap,
    ...historyKeymap,
    indentWithTab
  ])
];

const languageMap: Record<string, () => Promise<Extension>> = {
  bash: async () => {
    const module = await import('@codemirror/legacy-modes/mode/shell');
    return StreamLanguage.define(module.shell);
  },
  c: async () => {
    const module = await import('@codemirror/legacy-modes/mode/clike');
    return StreamLanguage.define(module.c);
  },
  clisp: async () => {
    const module = await import('@codemirror/legacy-modes/mode/commonlisp');
    return StreamLanguage.define(module.commonLisp);
  },
  clojure: async () => {
    const module = await import('@codemirror/legacy-modes/mode/clojure');
    return StreamLanguage.define(module.clojure);
  },
  cobol: async () => {
    const module = await import('@codemirror/legacy-modes/mode/cobol');
    return StreamLanguage.define(module.cobol);
  },
  coffeescript: async () => {
    const module = await import('@codemirror/legacy-modes/mode/coffeescript');
    return StreamLanguage.define(module.coffeeScript);
  },
  cpp: async () => {
    const module = await import('@codemirror/lang-cpp');
    return module.cpp();
  },
  crystal: async () => {
    const module = await import('@codemirror/legacy-modes/mode/crystal');
    return StreamLanguage.define(module.crystal);
  },
  csharp: async () => {
    const module = await import('@codemirror/legacy-modes/mode/clike');
    return StreamLanguage.define(module.csharp);
  },
  d: async () => {
    const module = await import('@codemirror/legacy-modes/mode/d');
    return StreamLanguage.define(module.d);
  },
  dart: async () => {
    const module = await import('@codemirror/legacy-modes/mode/clike');
    return StreamLanguage.define(module.dart);
  },
  elm: async () => {
    const module = await import('@codemirror/legacy-modes/mode/elm');
    return StreamLanguage.define(module.elm);
  },
  elixir: async () => {
    const module = await import('codemirror-lang-elixir');
    return module.elixir();
  },
  erlang: async () => {
    const module = await import('@codemirror/legacy-modes/mode/erlang');
    return StreamLanguage.define(module.erlang);
  },
  fsharp: async () => {
    const module = await import('@codemirror/legacy-modes/mode/mllike');
    return StreamLanguage.define(module.fSharp);
  },
  go: async () => {
    const module = await import('@codemirror/lang-go');
    return module.go();
  },
  groovy: async () => {
    const module = await import('@codemirror/legacy-modes/mode/groovy');
    return StreamLanguage.define(module.groovy);
  },
  guile: async () => {
    const module = await import('@codemirror/legacy-modes/mode/scheme');
    return StreamLanguage.define(module.scheme);
  },
  haskell: async () => {
    const module = await import('@codemirror/legacy-modes/mode/haskell');
    return StreamLanguage.define(module.haskell);
  },
  java: async () => {
    const module = await import('@codemirror/lang-java');
    return module.java();
  },
  javascript: async () => {
    const module = await import('@codemirror/lang-javascript');
    return module.javascript();
  },
  julia: async () => {
    const module = await import('@plutojl/lang-julia');
    return module.julia();
  },
  kotlin: async () => {
    const module = await import('@codemirror/legacy-modes/mode/clike');
    return StreamLanguage.define(module.kotlin);
  },
  lua: async () => {
    const module = await import('@codemirror/legacy-modes/mode/lua');
    return StreamLanguage.define(module.lua);
  },
  nix: async () => {
    const module = await import('@replit/codemirror-lang-nix');
    return module.nix();
  },
  ocaml: async () => {
    const module = await import('@codemirror/legacy-modes/mode/mllike');
    return StreamLanguage.define(module.oCaml);
  },
  pascal: async () => {
    const module = await import('@codemirror/legacy-modes/mode/pascal');
    return StreamLanguage.define(module.pascal);
  },
  perl: async () => {
    const module = await import('@codemirror/legacy-modes/mode/perl');
    return StreamLanguage.define(module.perl);
  },
  php: async () => {
    const module = await import('@codemirror/lang-php');
    return module.php();
  },
  python: async () => {
    const module = await import('@codemirror/lang-python');
    return module.python();
  },
  ruby: async () => {
    const module = await import('@codemirror/legacy-modes/mode/ruby');
    return StreamLanguage.define(module.ruby);
  },
  rust: async () => {
    const module = await import('@codemirror/lang-rust');
    return module.rust();
  },
  scala: async () => {
    const module = await import('@codemirror/legacy-modes/mode/clike');
    return StreamLanguage.define(module.scala);
  },
  swift: async () => {
    const module = await import('@codemirror/legacy-modes/mode/swift');
    return StreamLanguage.define(module.swift);
  },
  typescript: async () => {
    const module = await import('@codemirror/lang-javascript');
    return module.javascript({ typescript: true });
  },
};

type ChangeEventDetail = { value: string; revision: number };
type KeyboardBindingsName = "default" | "emacs" | "vim";

const defaultKeyboardBindingsExtension: Extension = [];

const keyboardBindingsMap: Record<Exclude<KeyboardBindingsName, "default">, () => Promise<Extension>> = {
  emacs: async () => {
    const module = await import("@replit/codemirror-emacs");
    return module.emacs();
  },
  vim: async () => {
    const module = await import("@replit/codemirror-vim");
    return module.vim();
  }
};

export class GlotCodeMirror extends HTMLElement {
  static get observedAttributes() {
    return [
      "value",
      "language",
      "disabled",
      "keyboard-bindings",
      "editor-revision",
      "editor-external-revision"
    ];
  }

  private _shadow: ShadowRoot;
  private _container: HTMLDivElement;
  private _view: EditorView | null = null;

  private _valueCache = "";
  private _languageName = "javascript";
  private _keyboardBindingsName: KeyboardBindingsName = "default";
  private _updatingFromOutside = false;
  private _revision = 0;
  private _acknowledgedRevision = 0;
  private _externalRevision = 0;
  private _valueSyncScheduled = false;
  private _handleRunShortcut = (event: KeyboardEvent) => {
    if (
      event.key !== "Enter" ||
      event.altKey ||
      event.shiftKey ||
      !(event.metaKey || event.ctrlKey)
    ) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    this.dispatchEvent(
      new CustomEvent("editor-run", {
        bubbles: true,
        composed: true
      })
    );
  };

  private _language = new Compartment();
  private _editable = new Compartment();
  private _keyboardBindings = new Compartment();

  constructor() {
    super();

    this._valueCache = initialDocumentValue(
      this.getAttribute("value"),
      this.textContent
    );
    this._languageName = (this.getAttribute("language") ?? "javascript").toLowerCase();
    this._keyboardBindingsName = this._parseKeyboardBindingsAttribute(
      this.getAttribute("keyboard-bindings")
    );
    this._revision = this._parseRevisionAttribute(this.getAttribute("editor-revision"));
    this._acknowledgedRevision = this._revision;
    this._externalRevision = this._parseRevisionAttribute(
      this.getAttribute("editor-external-revision")
    );

    this._shadow = this.attachShadow({ mode: "open" });

    const style = document.createElement("style");
    style.textContent = `
      :host {
        display: block;
        height: 100%;
      }

      .cm-wrapper, .cm-gutter {
        height: 100% !important;
      }

      .cm-gutter {
        min-width: 42px;
      }

      .cm-scroller {
        overflow: auto;
      }

      .cm-wrapper {
        border: 0;
        overflow: clip;
        height: 100%;
        font-family: "Lucida Console", Monaco, "Courier New", monospace;
        background:
          linear-gradient(
            180deg,
            var(--theme-screen-line) 0,
            var(--theme-screen-line) 1px,
            transparent 1px,
            transparent 4px
          ),
          var(--theme-page);
      }

      .cm-editor {
        height: 100%;
      }

      .cm-scroller {
        height: 100%;
      }
    `;

    this._container = document.createElement("div");
    this._container.className = "cm-wrapper";

    this._shadow.append(style, this._container);
  }

  connectedCallback() {
    if (this._view) return;

    const editableExt = EditorView.editable.of(!this.hasAttribute("disabled"));
    this._container.addEventListener("keydown", this._handleRunShortcut, {
      capture: true
    });

    const state = EditorState.create({
      doc: this._valueCache,
      extensions: [
        basicSetup,
        this._language.of([]),
        this._editable.of(editableExt),
        this._keyboardBindings.of(defaultKeyboardBindingsExtension),
        EditorView.updateListener.of((update) => {
          if (!update.docChanged) return;
          const next = update.state.doc.toString();
          this._valueCache = next;
          if (this._updatingFromOutside) return;
          this._revision += 1;
          // Emit a bubbling, composed CustomEvent so frameworks (like Elm) can listen.
          this.dispatchEvent(
            new CustomEvent<ChangeEventDetail>("change", {
              detail: { value: next, revision: this._revision },
              bubbles: true,
              composed: true
            })
          );
        })
      ]
    });

    this._view = new EditorView({
      state,
      parent: this._container
    });
    const view = this._view;

    // Load language extension async
    this._getLanguageExtension(this._languageName)?.then((ext) => {
      if (this._view === view && ext) {
        view.dispatch({ effects: this._language.reconfigure(ext) });
      }
    });

    this._getKeyboardBindingsExtension(this._keyboardBindingsName).then((ext) => {
      if (this._view === view) {
        view.dispatch({ effects: this._keyboardBindings.reconfigure(ext) });
      }
    });
  }

  disconnectedCallback() {
    this._container.removeEventListener("keydown", this._handleRunShortcut, {
      capture: true
    });

    this._discardView();
  }

  async attributeChangedCallback(name: string, _oldVal: string | null, newVal: string | null) {
    // Cache until the editor is ready
    if (!this._view) {
      if (name === "language") this._languageName = (newVal ?? "javascript").toLowerCase();
      if (name === "keyboard-bindings") {
        this._keyboardBindingsName = this._parseKeyboardBindingsAttribute(newVal);
      }
      if (
        name === "value" ||
        name === "editor-revision" ||
        name === "editor-external-revision"
      ) {
        this._scheduleValueSync();
      }
      return;
    }

    if (name === "value") {
      this._scheduleValueSync();
      return;
    }

    if (name === "editor-revision" || name === "editor-external-revision") {
      this._scheduleValueSync();
      return;
    }

    if (name === "language") {
      this._languageName = (newVal ?? "javascript").toLowerCase();
      const view = this._view;
      const ext = await this._getLanguageExtension(this._languageName);
      if (this._view === view) {
        view.dispatch({ effects: this._language.reconfigure(ext ?? []) });
      }
      return;
    }

    if (name === "keyboard-bindings") {
      this._keyboardBindingsName = this._parseKeyboardBindingsAttribute(newVal);
      const view = this._view;
      const ext = await this._getKeyboardBindingsExtension(this._keyboardBindingsName);
      if (this._view === view) {
        view.dispatch({ effects: this._keyboardBindings.reconfigure(ext) });
      }
      return;
    }

    if (name === "disabled") {
      const editable = !this.hasAttribute("disabled");
      this._view.dispatch({
        effects: this._editable.reconfigure(EditorView.editable.of(editable))
      });
      return;
    }
  }

  // Public API
  get value(): string {
    if (!this._view) return this._valueCache;
    return this._view.state.doc.toString();
  }
  set value(v: string) {
    this.setAttribute("value", v ?? "");
  }

  get language(): string {
    return this._languageName;
  }
  set language(name: string) {
    this.setAttribute("language", name);
  }

  get keyboardBindings(): KeyboardBindingsName {
    return this._keyboardBindingsName;
  }
  set keyboardBindings(name: KeyboardBindingsName) {
    this.setAttribute("keyboard-bindings", name);
  }

  get disabled(): boolean {
    return this.hasAttribute("disabled");
  }
  set disabled(flag: boolean) {
    if (flag) this.setAttribute("disabled", "");
    else this.removeAttribute("disabled");
  }

  focus(options?: FocusOptions) {
    super.focus(options);
    this._view?.focus();
  }

  // Helpers
  private _getLanguageExtension(name: string): Promise<Extension> | null {
    const factory = languageMap[name];
    if (!factory) {
      return null
    }

    return factory()
  }

  private _parseKeyboardBindingsAttribute(name: string | null): KeyboardBindingsName {
    switch ((name ?? "default").toLowerCase()) {
      case "emacs":
        return "emacs";
      case "vim":
        return "vim";
      default:
        return "default";
    }
  }

  private _parseRevisionAttribute(value: string | null): number {
    const revision = Number.parseInt(value ?? "0", 10);
    return Number.isSafeInteger(revision) && revision >= 0 ? revision : 0;
  }

  private _scheduleValueSync() {
    if (this._valueSyncScheduled) return;

    this._valueSyncScheduled = true;
    queueMicrotask(() => {
      this._valueSyncScheduled = false;
      this._synchronizeValue();
    });
  }

  private _synchronizeValue() {
    const renderedRevision = this._parseRevisionAttribute(
      this.getAttribute("editor-revision")
    );
    const externalRevision = this._parseRevisionAttribute(
      this.getAttribute("editor-external-revision")
    );
    const hasExternalUpdate = externalRevision !== this._externalRevision;
    const shouldApply = shouldApplyDocumentValue({
      localRevision: this._revision,
      acknowledgedRevision: this._acknowledgedRevision,
      externalRevision: this._externalRevision,
      renderedRevision,
      renderedExternalRevision: externalRevision
    });

    this._acknowledgedRevision = renderedRevision;
    this._externalRevision = externalRevision;
    this._revision = Math.max(this._revision, renderedRevision);

    const incoming = this.getAttribute("value") ?? "";
    if (hasExternalUpdate) {
      this._replaceViewDocument(incoming);
      return;
    }

    if (!shouldApply) return;

    if (!this._view) {
      this._valueCache = incoming;
      return;
    }

    if (incoming === this.value) return;

    this._updatingFromOutside = true;
    try {
      this._view.dispatch(documentUpdate(this._view.state, incoming));
    } finally {
      this._updatingFromOutside = false;
    }
  }

  private _replaceViewDocument(document: string) {
    this._valueCache = document;
    this._discardView();

    if (this.isConnected) {
      this.connectedCallback();
    }
  }

  private _discardView() {
    const view = this._view;
    this._view = null;

    view?.destroy();
    this._container.replaceChildren();
  }

  private _getKeyboardBindingsExtension(name: KeyboardBindingsName): Promise<Extension> {
    if (name === "default") {
      return Promise.resolve(defaultKeyboardBindingsExtension);
    }

    return keyboardBindingsMap[name]();
  }
}

customElements.define("glot-codemirror", GlotCodeMirror);

declare global {
  interface HTMLElementTagNameMap {
    "glot-codemirror": GlotCodeMirror;
  }
}
