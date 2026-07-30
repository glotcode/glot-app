# Frontend architecture

The frontend is a pair of Lustre applications: a public application and an
administration application. They share runtime capabilities, UI primitives,
and HTTP transport, while their feature state machines remain independent.

## Design goals

- A feature's state, messages, update logic, views, validation, and endpoint
  definitions are easy to find together.
- Application roots compose features and cross-cutting runtime capabilities;
  they do not contain feature business rules.
- Browser APIs and JavaScript interop are isolated behind small platform
  modules.
- HTTP transport is independent from endpoint definitions.
- Shared abstractions remove mechanical repetition without hiding state
  transitions or effects.
- Server and client rendering can share presentation without making domain
  modules depend on presentation code.

## Source layout

```text
src/glot_frontend/
  app/       Application roots and shared runtime state machines.
  public/    Public features, including the editor and snippet browser.
  account/   Authenticated account features.
  admin/     Administration features and their router.
  api/       HTTP client, response types, and endpoint modules.
  ui/        Reusable presentation and UI-state helpers.
  platform/  Browser capabilities and their FFIs.
```

Feature directories expose a small root module and keep implementation modules
below it. A stateful feature exposes a deterministic managed reducer and a thin
Lustre wrapper. The managed surface normally has this shape:

```gleam
pub opaque type Model
pub type Msg
pub type Command(msg)
pub fn init_managed(...) -> #(Model, Command(Msg))
pub fn update_managed(model: Model, msg: Msg, ...) -> #(Model, Command(Msg))
```

The page wrapper interprets commands with production ports and exposes the
Lustre `Effect`-returning API. Child state machines use the managed shape. The
feature root maps child messages and commands. Models are opaque outside their
owning feature unless callers have a concrete need to inspect them.

Stateful admin features use the same separation with an explicit directory
layout: `model.gleam` owns state, `message.gleam` owns events and callbacks,
`managed.gleam` owns pure initialization and updates, `view.gleam` owns Lustre
presentation, and the feature's `page.gleam` or `detail.gleam` is the thin
public facade. Shared DOM identifiers live in a feature-local constants module
when both the reducer and view need them.

Admin areas with distinct list and detail subfeatures use the equivalent
`list_model`, `list_message`, `list_managed`, and `list_view` naming (and the
matching `detail_*` modules). `list.gleam` and `detail.gleam` remain stable,
thin router-facing entry points; they do not own state transitions or markup.

Large composition points follow the same rule. The admin router keeps route
initialization, session resolution, and update orchestration in
`admin/router_managed`; `router_state`, `router_message`, and `router_view` own
the sum types and page dispatch view; and `router.gleam` remains a thin stable
facade. The managed router imports child model, message, and managed modules
directly so its transitive dependency graph does not pass through presentation
facades. Application session, heartbeat, and navigation transitions live in
`app/admin_managed` and the generic `app/public_managed` lifecycle reducer.
The admin lifecycle receives a generic `Pages` contract, so its transitive
dependency graph remains independent of the concrete router and presentation.
Their command values are interpreted only by the application production
boundary. Application composition lives in the pure `app/public_root_managed`
and `app/admin_root_managed` reducers. They own lifecycle and quick-action
coordination and emit application command algebras. `app/public` and
`app/admin` are only Lustre bootstrap shells; the matching
`app/*_root_production` modules are their production interpreters. Public
route-to-page state, messages, managed transitions, commands, presentation,
and production interpretation are split across the focused `app/public_page_*`
modules; `app/public_page` remains their stable facade. The admin root composes
the existing pure admin router modules directly. Top-bar search and selection
presentation lives in `app/public_quick_actions`.
Public page transitions report metadata changes as transition data. Editor
transitions derive that flag by comparing the pure metadata projection before
and after the state change, so metadata invalidation follows rendered SEO state
instead of duplicating it in a message classification.
`app/runtime` is pure shared state; HTTP-backed pageview and app-event operations
live in `app/runtime_production`.

Quick-action interaction state is shared by both applications through
`app/quick_actions_managed`. It emits typed dialog, scrolling, and selected-action
commands; application roots only build their available action sections and
interpret those commands with platform capabilities.

Admin reusable controls are imported directly from the focused `layout`,
`status`, `dialog`, `filter`, `form`, and `pagination` modules. There is no
aggregate UI facade: ownership and dependency intent stay explicit at every
call site.

The editor reducer delegates cohesive state transitions to `draft_update`,
`metadata_update`, `file_update`, `settings_update`, `save_update`, and
`execution_update`. Presentation is similarly split: `workspace_view` owns
tabs and editor-workspace rules; metadata, file, settings, save, restore-draft,
and snippet-information dialogs each own their presentation module; and
`dialog_controls` owns reusable choices. The root update and view modules
remain exhaustive dispatchers, making every new message visibly assigned to a
workflow.

Large admin detail pages keep data transformations and validation in focused
pure policy modules, such as `jobs/create_job_policy`,
`periodic_jobs/editor_policy`, `rate_limits/policy`, and
`users/editor_policy`. Modal and form markup lives in matching focused view
modules. Their root managed reducers are exhaustive dispatchers: loading and
pagination, editor/save, and destructive or creation workflows live in
focused `*_update` modules. Login and account snippet management follow the
same workflow ownership. Managed reducers own lifecycle and commands; they do
not accumulate request mapping, validation, or large presentation helpers. Pure filter
classification shared by a reducer and view belongs in a feature-local policy
module such as `users/list_filter`.

Admin configuration follows the same dependency boundary at two levels.
`config/page_managed`, `page_model`, and `page_message` compose section state
and commands without importing Lustre presentation; `page_view` composes the
section views. Each configuration section owns its managed state transitions
and request mapping in its feature module and exports markup from a matching
`*_view` module. `config/section` contains the generic pure form state machine,
while `config/section_view` contains its reusable card and status presentation.

Job-type policies and periodic-job lists use the standard focused naming:
model, message, managed reducer, pure policy where applicable, and view. Their
root modules are stable facades only. The managed admin router imports the
focused modules directly, preserving a presentation-free transitive graph.

The account reducer follows the same workflow decomposition. Its root update is
an exhaustive dispatcher, while initialization, profile, session, passkey, and
account-access/deletion transitions live in focused workflow modules. New
account messages must be assigned explicitly in the root dispatcher.
Account session and passkey presentation uses explicit `*_view` modules beside
their workflow modules. Login, public snippets, and account snippet management
also keep Lustre markup in `view.gleam`; their `page.gleam` modules only expose
stable lifecycle facades and interpret production commands.

## Dependency direction

```text
app -> features -> api / ui / platform -> glot_web -> glot_core
                                \---------------------> glot_core
```

- `app` may import any feature that it composes.
- A feature may import its own child modules, `api`, `ui`, `platform`, and
  domain/contracts from `glot_core`. Shared server/client presentation comes
  from `glot_web`.
- Features must not import unrelated features. Shared behavior moves to the
  narrowest appropriate `ui`, `platform`, or domain module.
- `api/client` owns transport. Endpoint modules own action selection and DTO
  codecs. UI modules do not construct HTTP requests.
- `platform` modules are the only frontend modules that directly bind browser
  APIs through FFI.
- Domain modules must not import frontend presentation or platform modules.
- `glot_core` is presentation-free. Lustre elements, attributes, and shared
  page views belong to `glot_web`; browser-only effects belong to the
  frontend.

## State and effects

- Updates remain explicit. A message should make the triggering event clear,
  and the corresponding branch should make both the state transition and
  effect visible.
- Features with multi-step workflows should return a feature-owned command
  algebra from their reducer. Keep browser and HTTP execution in one thin
  production interpreter so the reducer remains deterministic and an
  in-memory interpreter can drive integration scenarios.
- Commands contain typed requests and response-to-message callbacks. Do not
  duplicate endpoint behavior in tests or replace typed commands with string
  operation names.
- Keep managed initialization and reducers transitively free of browser APIs,
  HTTP endpoint interpreters, navigation, and `Effect`. Pure models, codecs,
  policies, and UI state may be shared with them; storage and timer adapters
  may not.
- Put runtime capabilities in a feature-owned `Ports` bundle. The production
  ports module is the only feature module that assembles API, storage, dialog,
  timer, focus, and navigation implementations for the interpreter.
- Split pure state and codecs from their runtime adapters. For example,
  `draft` and `settings` are pure, while `draft_store` and `settings_store`
  own browser persistence.
- Editor draft persistence is split further by responsibility:
  `draft_persistence` owns stable keys, serialization, corruption detection,
  and expiration decisions; `draft_repository` executes those decisions
  against injected synchronous storage functions; and `draft_store` only
  assembles the production clock and local-storage implementations. Tests use
  repository functions directly and never invoke browser FFI.
- Use `Loadable(a)` for asynchronous reads and `MutationState` for writes.
- A child owns request validation and maps successful responses back into its
  saved and draft state.
- Stale asynchronous responses must carry enough identity or generation data
  to be rejected safely. Admin cursor lists own an opaque
  `admin/cursor_request.State`; `cursor_request.begin` advances the state and
  returns the generation attached to the request. Other request streams use
  the opaque `admin/request_generation.Generation` type directly. Features
  never construct or increment raw generation integers.
- Extract pure state transitions before introducing a generic abstraction.
  Do not build schema-driven forms or erase feature-specific message types.

## Presentation

- Feature views live with their feature. Reusable, domain-neutral controls live
  under `ui`.
- CSS keeps its explicit cascade layers. Page-specific styles may remain in
  feature-named stylesheets; moving Gleam modules does not require bundling CSS
  into components. `css/ARCHITECTURE.md` defines ownership and
  `npm run check:css` enforces the layer, entry-point, color-token, and
  accessibility-media contracts.
- Shared server/client Lustre views live in the shared web presentation area,
  separate from pure domain and API contract modules.

## Tests

The `test` tree mirrors `src`. Prefer focused tests for pure policies,
transitions, and feature reducers over broad markup snapshots. Every stateful feature should
cover loading, success, failure, editing, reset, mutation success/failure, and
stale-response behavior where applicable. Transport decoding is tested
separately from endpoint construction.

Integration scenarios run without a browser. They dispatch the same messages
as the UI, execute the production reducer, inspect typed commands, complete API
commands with fixture responses, and render the resulting Lustre view. The
scenario interpreter must keep API work pending until a fixture explicitly
completes it, keep timers pending until explicitly delivered, and fail when a
scenario leaves unexpected work pending. Environment, SSR, settings, storage,
and API responses are all fixtures. This also makes response ordering and
stale-response behavior deterministic.

Application lifecycle scenarios additionally cover session resolution and
route transitions. Every data-backed admin route must emit a typed initial
request when initialized for an authorized administrator. Tests must complete
at least one navigation-time request through its real callback so request
generation and retained loading state are exercised together.
Responses delivered after navigation has replaced the owning page must be
ignored. Mutation scenarios cover validation or reset/cancel, API failure,
retry, success, and stale response rejection across admin editors. Account and
public scenarios apply the same fixture-driven coverage to sessions, passkeys,
snippet deletion, and login.

Rendered integration views also run through the browserless accessibility
contract in `test/support/accessibility.gleam`. It checks explicit button
types, named form controls, image alternatives, accessible dialog names, and
resolved ARIA relationships. Representative feature tests and a deliberately
invalid fixture protect both the application markup and the auditor itself
without introducing a DOM emulator.

FFI is not mocked at the JavaScript boundary. Managed reducers emit typed
commands for browser capabilities, and scenario adapters record or schedule
those commands as data. Production interpreters are the only code that turns
them into platform calls. This keeps integration tests deterministic while
testing the same reducer and callback wiring used in production.

`test/support/managed_scenario.gleam` is the shared scenario kernel. It owns
model state, pending fixture work, observed external effects, dispatch, and
pending-effect completion. Feature adapters only interpret their own command
algebra and add feature-specific fixture helpers. The editor adapter is the
reference for commands that distinguish API work, browser observations, and
explicitly delivered timers.

Integration suites live under their owning feature path. In particular, admin
mutation scenarios are split across `test/admin/jobs`, `periodic_jobs`,
`rate_limits`, and `users`, so fixtures and failures point directly to the
workflow being exercised.

The editor is treated as a critical workflow. Its integration coverage is
split by initialization and draft recovery, editing and settings, execution,
and saving. Each scenario asserts typed request payloads, reducer state,
observable browser commands, rendered user feedback, and pending-effect
exhaustion where the workflow is complete. Editor markup is also audited across
lifecycle, failure, result, and populated-dialog states.

`npm run check:boundaries` reads `scripts/managed-boundaries.json`, walks every
configured feature's transitive imports, and rejects runtime adapters, FFI
declarations, transport interpreters, and `Effect`. New managed feature modules
must be added to that configuration. Run it with the normal frontend test
suite.

## Change checklist

When adding or changing a feature:

1. Put code in the owning feature namespace rather than the repository root.
2. Keep the root page focused on composition.
3. Represent endpoint work in the feature command algebra and execute it from
   production ports, not from the reducer.
4. Put browser access behind `platform` and expose it to reducers as commands.
5. Reuse domain types from `glot_core`.
6. Add policy tests for validation and mapping, plus reducer tests for new state
   transitions.
7. Add every managed reducer entry point to `scripts/managed-boundaries.json`.
8. Run `npm test` and `npm run build`.
