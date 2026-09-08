# Editor compatibility matrix

Captured from the locked CodeMirror packages and the actual Glot editor
configuration **before** those dependencies were removed, so that the native
Gleam editor can be measured against what users could really reach.

Sources inspected:

- `@codemirror/commands` 6.x — `standardKeymap`, `emacsStyleKeymap`,
  `defaultKeymap`, `historyKeymap`, `indentWithTab`.
- `@codemirror/search` 6.x — `searchKeymap`, search panel.
- `@replit/codemirror-vim` 6.3 → `@replit/codemirror-vim-core` 0.1
  (`defaultKeymap`, `defaultExCommandMap`).
- `@replit/codemirror-emacs` 6.1 (`emacsKeys`).
- `js/custom_elements/glot-codemirror.ts` — the extension set Glot actually
  enabled.

## What Glot actually enabled

`basicSetup` in `glot-codemirror.ts` was:

```
lineNumbers, highlightActiveLineGutter, history, drawSelection, dropCursor,
indentOnInput, bracketMatching, rectangularSelection, highlightActiveLine,
highlightSelectionMatches, editorTheme, syntaxHighlighting(default),
syntaxHighlighting(glot), keymap.of([defaultKeymap, searchKeymap,
historyKeymap, indentWithTab])
```

Consequences that bound the replacement scope:

- **No autocompletion.** `@codemirror/autocomplete` was a dependency, but no
  `autocompletion()` extension was installed. Emacs `M-/` (`startCompletion`)
  and any completion keymap were therefore dead keys.
- **No bracket auto-closing** (`closeBrackets` absent), **no folding**
  (`foldGutter`/`codeFolding` absent, so vim `zf`/`zo`/`zc` were inert),
  **no linting**, **no LSP**.
- **No `crosshairCursor`, no `highlightSpecialChars`, no
  `allowMultipleSelections`.** Multi-range selections could only be produced by
  `rectangularSelection` (Alt-drag), and `addCursorAbove`/`addCursorBelow`
  (`Mod-Alt-Arrow`) silently collapsed because `EditorState.allowMultipleSelections`
  was never turned on.
- **No syntax tree in most languages.** 30 of the 35 mapped languages used
  `StreamLanguage`, which exposes no real syntax tree, so `cursorSyntaxLeft`,
  `cursorSyntaxRight` and `selectParentSyntax` (`Alt-Arrow`, `Mod-i`) were
  no-ops or degenerate there.
- **9 of the 44 supported languages had no highlighting at all**: Plaintext,
  Assembly, Ats, Hare, Idris, Mercury, Nim, Raku, Sac, Zig (`languageMap` had
  no entry, `_getLanguageExtension` returned `null`).
- **Shadow DOM.** The editor lived in a shadow root, so the page's own
  `Ctrl/Cmd`-based quick actions could not see editor keystrokes, and the
  element re-created its whole view on every external document change.

## Default keymap (no Vim/Emacs)

`Mod` = `Cmd` on macOS, `Ctrl` elsewhere.

| Key | Command | Native editor |
| --- | --- | --- |
| ArrowLeft / ArrowRight | cursorCharLeft/Right (+Shift selects) | yes |
| Mod-ArrowLeft/Right (mac: Alt-) | cursorGroupLeft/Right | yes |
| Cmd-ArrowLeft/Right (mac) | cursorLineBoundaryLeft/Right | yes |
| ArrowUp / ArrowDown | cursorLineUp/Down (+Shift selects) | yes |
| Cmd-ArrowUp/Down (mac) | cursorDocStart/End | yes |
| Ctrl-ArrowUp/Down (mac) | cursorPageUp/Down | yes |
| PageUp / PageDown | cursorPageUp/Down | yes |
| Home / End | cursorLineBoundaryBackward/Forward | yes |
| Mod-Home / Mod-End | cursorDocStart/End | yes |
| Enter, Shift-Enter | insertNewlineAndIndent | yes |
| Mod-a | selectAll | yes |
| Backspace / Delete | deleteCharBackward/Forward | yes |
| Mod-Backspace (mac Alt-) | deleteGroupBackward | yes |
| Mod-Delete (mac Alt-) | deleteGroupForward | yes |
| Cmd-Backspace / Cmd-Delete (mac) | deleteLineBoundaryBackward/Forward | yes |
| Ctrl-b/f/p/n/a/e (mac) | char/line/line-boundary movement | yes |
| Ctrl-d / Ctrl-h (mac) | deleteCharForward / deleteCharBackward | yes |
| Ctrl-k (mac) | deleteToLineEnd | yes |
| Ctrl-Alt-h (mac) | deleteGroupBackward | yes |
| Ctrl-o (mac) | splitLine | yes |
| Ctrl-t (mac) | transposeChars | yes |
| Ctrl-v (mac) | cursorPageDown | yes |
| Alt-ArrowUp / Alt-ArrowDown | moveLineUp / moveLineDown | yes |
| Shift-Alt-ArrowUp / Down | copyLineUp / copyLineDown | yes |
| Escape | simplifySelection | yes |
| Mod-Enter | insertBlankLine | **no — reserved for Run** (was already shadowed by the element's `editor-run` capture handler) |
| Alt-l (mac Ctrl-l) | selectLine | yes |
| Mod-[ / Mod-] | indentLess / indentMore | yes |
| Mod-Alt-\\ | indentSelection | yes |
| Shift-Mod-k | deleteLine | yes |
| Shift-Mod-\\ | cursorMatchingBracket | yes |
| Mod-/ | toggleComment | yes |
| Alt-A | toggleBlockComment | yes |
| Tab / Shift-Tab | indentMore / indentLess | yes (with a documented escape, see below) |
| Mod-z | undo | yes |
| Mod-y (mac Mod-Shift-z) | redo | yes |
| Mod-u / Alt-u | undoSelection / redoSelection | yes |
| Mod-f | openSearchPanel | yes |
| F3 / Mod-g (+Shift) | findNext / findPrevious | yes |
| Escape (in panel) | closeSearchPanel | yes |
| Mod-Shift-l | selectSelectionMatches | yes |
| Mod-Alt-g | gotoLine | yes |
| Mod-d | selectNextOccurrence | yes |
| Alt-ArrowLeft/Right, Mod-i | syntax movement | **no** — required a real syntax tree that 30/35 languages never had |
| Mod-Alt-ArrowUp/Down | addCursorAbove/Below | **no** — inert without `allowMultipleSelections` |
| Ctrl-m (mac Shift-Alt-m) | toggleTabFocusMode | replaced by the documented Tab escape below |

### Tab escape

CodeMirror's `toggleTabFocusMode` was the escape from Tab indentation, bound to
`Ctrl-m` everywhere except macOS and to `Shift-Alt-m` there. The native editor
accepts **both chords on every platform**, so the escape can be documented as
one thing, and announces the new state in the editor's status region.

While tab focus mode is on, the editor moves focus itself rather than letting
the key through, so the escape works even when several keys arrive before the
next render.

## Vim coverage

From `@replit/codemirror-vim-core` `defaultKeymap`. Everything listed is
implemented natively unless the note says otherwise.

**Key-to-key:** `<Left> <Right> <Up> <Down> g<Up> g<Down> <Space> <BS> <Del>
<C-Space> <C-BS> <S-Space> <S-BS> <C-n> <C-p> <C-[> <C-c> <C-Esc> s S <Home>
<End> <PageUp> <PageDown> <CR> <Ins>`.

**Motions:** `h j k l w W e E b B ge gE 0 ^ $ + - _ { } ( ) H M L G gg
g0 g^ g$ gj gk f F t T ; , % | ' ` ]` [` ]' [' ]<char> [<char> n N gn gN
<C-f> <C-b> <C-d> <C-u>`, plus `o`/`O` in visual mode (other end of selection).

**Operators:** `d y c = > < g~ gu gU gc gq gw g?`.

**Operator-motion:** `x X D Y C ~`, and in insert mode `<C-u>` `<C-w>`.

**Actions:** `a A i I gi gI o O v V <C-v> <C-q> gv J gJ p P ]p [p r<char>
q<register> @<register> R u U <C-r> m<register> "<register> <C-r><register>
<C-o> zz z. zt z<CR> zb z- . <C-a> <C-x> <C-t> <C-d> <C-e> <C-y> <C-i>`.

**Text objects:** `a<obj>` / `i<obj>` for `w W s p ( ) b [ ] { } B < > t ' " ``.

**Search:** `/ ? * # g* g#`.

**Ex commands** (`:`): the upstream map lists 37 names. Reachable and
meaningful in Glot: `:w[rite]` (saves the snippet), `:u[ndo]`, `:red[o]`,
`:s[ubstitute]`, `:g[lobal]`, `:v[global]`, `:sor[t]`, `:d[elete]`, `:y[ank]`,
`:pu[t]`, `:j[oin]`, `:norm[al]`, `:noh[lsearch]`, `:se[t]`/`:setl`/`:setg`
(for the options Glot exposes), `:marks`, `:reg[isters]`, `:delm[arks]`,
`:start[insert]`, and line-number/range addressing.

Not implemented, and deliberately so — these configure an editor environment
Glot does not have: `:colo[rscheme]`, the twelve `:map`/`:noremap`/`:unmap`/
`:mapclear` variants (Glot has no user configuration system; see the plan's
stated defaults).

Upstream commands that were **already broken or inert** in Glot's
configuration and are therefore corrected rather than reproduced:

- `zf`, `zo`, `zc`, `za` — folding was never enabled.
- `<C-e>` / `<C-y>` scrolled a viewport the shadow-DOM host mis-sized.
- `<C-i>`/`<C-o>` jumplist entries survived across file switches, which now
  belong to per-file sessions.

## Emacs coverage

From `@replit/codemirror-emacs` `emacsKeys`.

**Movement (mark-aware via `goOrSelect`):** `C-p C-n C-b C-f M-b M-f C-a C-e
S-M-, S-M-. C-v M-v C-Up C-Down PageUp PageDown Home End C-Home C-End` and the
arrow keys.

**Selection:** `S-Up S-Down S-Left S-Right S-C-p S-C-n S-C-b S-C-f S-C-Left
S-C-Right S-M-b S-M-f S-Home S-End S-C-a S-C-e S-C-Home S-C-End S-C-Up
S-C-Down`, `C-x C-p` / `C-x h` (select all), `M-h` (select paragraph).

**Mark and region:** `C-Space` (set mark), `C-x C-x` (exchange point and
mark), `Esc` (unset transient mark), `C-g` (keyboard quit).

**Kill ring:** `C-w` (kill region), `M-w` (kill-ring save), `C-k` (kill line),
`M-d` / `C-Delete` (kill word right), `C-Backspace` / `M-Backspace` /
`M-Delete` (kill word left), `C-y` / `S-Delete` (yank), `M-y` (yank rotate).

**Editing:** `Backspace`, `Delete` / `C-d`, `Return` / `C-m`, `C-o`
(split line), `C-t` (transpose chars), `M-;` (toggle comment),
`M-u` / `M-l` (upcase/downcase word), `C-x C-u` / `C-x C-l` (region case),
`C-/`, `C-x u`, `C-z`, `S-C--` (undo), `S-C-/`, `C--`, `S-C-z` (redo).

**Search:** `C-s`, `C-r` (search panel), `M-C-s`, `M-C-r` (find next/previous),
`S-M-5` (replace).

**Prefixes and prompts:** `C-u` (universal argument), `C-x` prefix, `M-x`
(command prompt), `M-g` (goto line), `C-l` (recenter top/bottom), `M-s`
(center selection).

**Rectangles:** `C-x r` (rectangular region).

Corrections to demonstrable upstream bugs (the plan asks for these to be fixed,
not reproduced):

| Upstream | Bug | Native behaviour |
| --- | --- | --- |
| `PageUp` / `M-v` / `C-Up` | the selecting branch called `selectPageDown` | selects page **up** |
| `C-x C-l` | mapped to `changeCase {dir: 1}` (upcase), same as `C-x C-u` | downcases the region |
| `M-@` / `M-S-2` (`markWord`) | registered as an empty function | marks the word after point |
| `M-/` | bound to `startCompletion` with no autocomplete extension installed | unbound (no autocomplete in Glot) |
| `C-x r` | selected a rectangle but multi-range selection was disabled | selects a real rectangular region |

## Chords the browser keeps

Some combinations cannot be cancelled by a page in Chrome, Firefox or Safari.
CodeMirror could not receive them either; the difference is that the native
editor states plainly which ones they are and routes the affected commands
somewhere reachable.

| Chord | Owned by the browser for | Reach the command instead by |
| --- | --- | --- |
| `Mod-t`, `Mod-n`, `Mod-w`, `Mod-q` | new tab, new window, close tab, quit | Emacs `C-t` → `M-x transpose-chars`; `C-w` → `M-x kill-region`; `C-n` → `ArrowDown` |
| `Mod-Tab`, `Alt-Tab` | window switching | `Escape` then `Tab` leaves the editor |
| `F1`, `F5`, `F11`, `F12` | help, reload, full screen, dev tools | — |

Everything else the editor binds *is* cancellable, including `Ctrl-R` (Vim
redo, Emacs reverse search) and `Ctrl-P` (Emacs previous line), which the
editor claims only while Vim or Emacs bindings are selected.

## Precedence

While the editor has focus:

1. `Ctrl/Cmd-Enter` always runs the snippet.
2. Vim or Emacs bindings, when that mode is selected.
3. The default editor keymap.
4. Browser-reserved combinations are never swallowed and never fall through to
   an editing command.

Glot quick actions remain reachable from outside the editor.
