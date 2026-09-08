# AGENTS.md

Repository instructions for future agent sessions.

## Structure

- `glot_backend` contains the backend application.
- `glot_core` contains shared domain types and helpers.
- `glot_frontend` contains the frontend application.

## Backend Conventions

- Follow the feature organization and dependency boundaries documented in
  `glot_backend/ARCHITECTURE.md`.
- Prefer domain types from `glot_core` over duplicating equivalent backend-local types.
- `glot_backend/program/handlers.gleam` is the boundary where SQL rows should be converted into domain types.
- Keep generated SQL row types confined to the DB layer when possible.
- Never import `glot_backend/sql` from domain modules. Domain modules should not depend on generated SQL row types or query-layer types; convert at the DB/program handler boundary first.
- For imports from domain modules, only import the main type from `.{type ...}` imports. Example: from `glot_core/api_action`, import `ApiAction`; do not import constructors like `RunAction` or `SendLoginTokenAction` directly.
- In type positions, prefer the directly imported main type, e.g. `import glot_core/api_action.{type ApiAction}` and then `action: ApiAction`.
- In value positions, constructors and module functions should still be referenced through the module namespace, e.g. `api_action.LoginAction`, `api_action.to_string(action)`, or `user_action.UserAction(...)`.
- If a file needs both type annotations and module-qualified values from the same module, prefer keeping the `.{type ...}` import and also use the module namespace if Gleam requires it for value references.
- Avoid destructuring nested structures in patterns unless it is clearly simpler. Prefer simple bindings and read nested fields directly where that improves readability. Avoid introducing `as c`-style whole-value aliases unless they actually make the code clearer.
- When logic has several sequential steps or guards, prefer flattening it with small helpers and `use`-style early exits instead of nesting `case` expressions.
- Keep transaction bodies as declarative and free of business logic as possible. Prepare domain decisions and mutation programs in small helpers, then execute the composed mutations together in one transaction.
- Prefer returning and composing `TransactionProgram` values. Use `transaction_program.sequence` for ordered mutations and `and_then` only when a later operation depends on an earlier result.
- Keep reads required for locking or atomic decisions, such as `FOR UPDATE` queries, inside the same transaction as their mutations. Isolate the decision and mutation preparation from the transaction orchestration in small helpers.

### Feature Effect Boundaries

- When a feature has multiple effect algebras, combine them in the feature-root
  `effect/algebra.gleam` and expose one global effect variant for the feature.
- Subfeature effect modules must construct global effects through the
  feature-root `effect/effect.gleam`. They must not construct the feature's
  `program_types` variant directly.
- The feature-root interpreter must accept a feature-owned `Ports` bundle when
  it needs multiple dependencies. System interpreters must pass the bundle,
  not extract and pass its individual ports.
- Subfeature algebras own their operation trace names and string conversions.
  The feature-root algebra combines those names, and the global trace module
  depends only on the feature-root algebra.
- Adding an operation or subfeature to an existing bundled feature must not add
  another global DB effect, global trace variant, or individual system-level
  port.

## Frontend Conventions

- Follow the layering and managed-effect rules documented in
  `glot_frontend/ARCHITECTURE.md`.
- The code editor lives in `glot_frontend/src/glot_frontend/public/editor/code_editor`.
  It is plain Gleam and Lustre; there is no CodeMirror and no editor custom
  element. Keep editing, history, search, keybindings and lexing in pure
  modules, and keep browser access in `platform/code_editor_dom`.
- Every language in `glot_core/language.list()` must keep its own lexer rules in
  `code_editor/syntax`; a language must never fall back to a generic lexer.
- After editor changes, run `npm test`, `npm run test:browser` and
  `node scripts/benchmark-editor.mjs` in `glot_frontend`, and record real-device
  results in `glot_frontend/docs/editor-verification.md`.

## Generated Files

- `glot_backend/src/glot_backend/sql.gleam` is generated. Do not hand-edit it unless the task explicitly requires a temporary/manual fix.
- `./run_parrot.sh` is the script used to generate `glot_backend/src/glot_backend/sql.gleam`.
- Prefer changing the SQL source files or generation inputs, then regenerating `sql.gleam`.

## Database

- `glot_backend/priv/db/migrations` is the schema source of truth used by the backend at startup.
- `glot_backend/priv/db/seeds/<APP_ENV>` contains environment-specific startup seeds tracked in `schema_seeds`.
- `0000_bootstrap.sql` is the reserved bootstrap migration and must remain first in `glot_backend/priv/db/migrations`.
- The backend starts in maintenance mode and only enters running mode after startup migrations and environment-specific seeds complete successfully.

## Validation

- After backend changes, run `gleam test` in `glot_backend`.
- After frontend changes, run `npm test` and `npm run build` in `glot_frontend`.
- After changes to shared server-rendered markup, run `gleam test` in `glot_web`.
