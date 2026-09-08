# Frontend architecture

The frontend contains two Lustre applications: a public application and an
administration application. They share runtime capabilities, transport, and UI
primitives while keeping their feature state machines independent.

## Design goals

- Keep feature state, messages, transitions, commands, and presentation close
  to the feature that owns them.
- Keep application roots focused on composition and cross-cutting lifecycle
  concerns rather than feature rules.
- Make state transitions and effects explicit, deterministic, and testable
  without a browser.
- Isolate HTTP, browser APIs, storage, timers, and JavaScript interop behind
  narrow production boundaries.
- Share mechanical infrastructure without erasing domain-specific types or
  hiding important behavior.

## Source layout

```text
src/glot_frontend/
  app/       Application composition and shared runtime state machines.
  public/    Public features.
  account/   Authenticated account features.
  admin/     Administration features and routing.
  api/       HTTP transport, response types, and endpoint modules.
  ui/        Reusable presentation and UI-state helpers.
  platform/  Browser capabilities and their FFIs.
```

Feature directories expose a small, stable public surface and keep their
models, messages, transitions, commands, policies, and views in focused
modules. Feature roots compose those modules; they should not become a second
home for their implementation.

## Dependency direction

```text
app -> features -> api / ui / platform -> glot_web -> glot_core
                                \---------------------> glot_core
```

- Application modules may import the features they compose.
- Features may import their own child modules and shared API, UI, platform,
  presentation, and domain modules.
- Features must not depend on unrelated features. Shared behavior belongs in
  the narrowest appropriate shared layer.
- `api/client` owns HTTP transport. Endpoint modules own action selection and
  DTO codecs. UI modules do not construct HTTP requests.
- `platform` is the only frontend layer that binds browser APIs through FFI.
- `glot_core` remains presentation-free. Shared server/client presentation
  belongs to `glot_web`; browser-only behavior belongs to the frontend.

## State and effects

Stateful features separate deterministic transitions from production effects.
A managed reducer receives a model and message and returns the next model plus
a typed command. A thin production interpreter executes those commands using
feature-owned runtime ports and maps results back into messages.

The usual managed surface is:

```gleam
pub opaque type Model
pub type Msg
pub type Command(msg)
pub fn init_managed(...) -> #(Model, Command(Msg))
pub fn update_managed(model: Model, msg: Msg, ...) -> #(Model, Command(Msg))
```

- Messages describe events; update branches make the resulting transition and
  command visible.
- Commands contain typed requests and response-to-message callbacks.
- Managed reducers remain transitively independent of Lustre `Effect`, HTTP
  interpreters, browser APIs, navigation implementations, timers, and storage
  adapters.
- Runtime dependencies are assembled in feature- or application-owned port
  bundles at the production boundary.
- Pure models, codecs, policies, and projections remain separate from their
  runtime adapters.
- Parent reducers map child messages and commands explicitly. Child state
  machines own their internal invariants.
- Asynchronous work carries typed identity or generation state when stale or
  reordered responses are possible.
- Shared abstractions are introduced after repeated pure transitions reveal a
  stable common structure; feature-specific state and message types remain
  explicit.

Application roots use the same separation. Pure root reducers coordinate
application lifecycle, routing, and shared interactions; bootstrap modules and
production interpreters are thin effectful shells.

### Route presentation

SPA navigation separates the page being prepared from the page being
presented. A router may initialize a destination and run its commands while
`app/page_presentation` keeps the previous page mounted. The destination is
committed atomically once its root page state reports that it can render
meaningful content. Public metadata is committed with the presented page, not
when loading starts. Browser scrolling and focus are also deferred until the
same presentation commit; changing browser history alone must not mutate the
outgoing document.

This mirrors document navigation: the current document remains visible while
the next one is loading. New asynchronous page variants must define their
presentability policy. Successful data, useful empty states, terminal error
states, and deliberately revealed delayed-loading states are presentable;
transient initialization and hidden loading states are not. Request identity
belongs to a feature when multiple operations can overlap within the same
route. Route-scoped page messages reject work originating from a route that is
no longer current. Each feature model owns its presentability decision, while
`public_page_state` only combines those decisions across public page variants
and `admin/router_state` combines them across admin variants. Admin navigation
owns one root-level delayed loader because its pages expose immediate loading
states rather than feature-level loading-delay streams.

Filterable admin lists treat the URL as the applied-state boundary. Each
feature owns the names, parsing, validation, defaults, and canonical encoding
of its filter fields; the shared route only preserves the raw query. Applying
filters and moving between cursor pages emits typed navigation, which creates
a fresh routed model and request. This makes direct loads, refreshes, and
history traversal reproduce the same list state. Draft form input may remain
local until the user applies it.

Admin page commands and messages carry the route that originated them. The
root accepts a page message only while that exact route is still current.
Transport cancellation remains the prompt resource cleanup mechanism, while
route identity is the correctness boundary for responses that were already
queued when navigation began.

## The code editor

`public/editor/code_editor` is a child feature of the editor page and follows
the same managed model, message, command and interpreter pattern as any other
feature. It replaces the previous CodeMirror custom element outright; there is
no editor custom element, no shadow DOM, and no second Lustre application.

- Editing is deterministic Gleam. The document is an indexed line list, every
  change is a transaction, and undo grouping, selection mapping, search, the
  keybinding state machines and the lexers are all pure and testable without a
  browser.
- Offsets are UTF-16 code units at every browser interface, because that is what
  `selectionStart` and `beforeinput` ranges use. Movement and deletion are
  grapheme-aware; `code_editor/text` is the only place the two are converted.
- Presentation is ordinary Lustre elements: a `textarea` that holds the whole
  document and owns focus, the caret, native and touch selection and IME, with a
  highlighting layer behind it that renders only the visible lines plus
  overscan. Both share one typography and neither soft-wraps.
- Browser interop lives in `platform/code_editor_dom`. It writes values,
  selections and scroll positions, measures geometry, observes resizes and
  reaches the clipboard. It never decides what a command means, and it never
  owns history.
- Native edits are reconciled rather than intercepted. The browser is allowed to
  edit the textarea — that is what keeps IME, dictation, autocorrect and mobile
  keyboards working — and `code_editor/reconcile` diffs the result into one
  transaction.
- Each open file, and stdin, has its own session with a stable key that is
  independent of the filename and of the file's position. Switching tabs changes
  the active key; history, cursor, selection and scroll survive. Explicit
  document replacement starts a new generation, and browser callbacks quoting a
  stale session or generation are dropped.
- Every language in `glot_core/language.list()` has its own lexer rules under
  `code_editor/syntax`. The scanner is incremental: it caches lexical state per
  line and rescans from a change until the state converges. An exhaustive test
  fails if a language ever loses its rules.

## Presentation

- Feature views live with their feature. Reusable, domain-neutral controls live
  under `ui`.
- Views render state and emit messages; they do not own transport or browser
  effects.
- Shared server/client Lustre views live in `glot_web`, separate from pure
  domain and API contract modules.
- CSS retains explicit cascade layers and may remain organized independently
  from Gleam modules. `css/ARCHITECTURE.md` defines CSS ownership and enforced
  constraints.

## Testing and enforcement

The `test` tree mirrors `src`. Prefer focused tests of pure policies and
reducers, supplemented by browserless integration scenarios that drive the
same messages, commands, callbacks, and views used in production.

Integration interpreters keep external work explicit and pending until a
fixture completes it. This makes failures, retries, response ordering, stale
responses, timers, storage, navigation, and observable browser commands
deterministic. Rendered integration views also run through the shared
accessibility contract.

FFI is not mocked at the JavaScript boundary. Tests exercise managed reducers
and interpret their typed commands as data; only production interpreters call
platform implementations.

`npm run check:boundaries` enforces that configured managed entry points remain
transitively independent of runtime adapters, FFI declarations, transport
interpreters, and Lustre `Effect`. New managed entry points must be added to
`scripts/managed-boundaries.json`.

## Change checklist

When adding or changing a feature:

1. Put code in the owning feature namespace.
2. Keep application and feature roots focused on composition.
3. Represent external work in typed commands and execute it at the production
   boundary.
4. Put browser access behind `platform`.
5. Reuse domain types from `glot_core`.
6. Add focused policy and reducer tests plus integration coverage proportional
   to the workflow risk.
7. Register new managed entry points with the boundary checker.
8. Run `npm test` and `npm run build`.

Editor changes additionally run `npm run test:browser` (Chromium, Firefox and
WebKit) and `node scripts/benchmark-editor.mjs`. `docs/editor-verification.md`
records the benchmark results and the real-device and screen-reader checks that
cannot be automated; `docs/editor-compatibility-matrix.md` records the command
coverage the editor is measured against.
