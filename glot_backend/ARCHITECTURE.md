# Backend architecture

The backend is organized by feature. A feature owns its domain workflows,
effects, ports, adapters, and SQL sources. Shared runtime and composition code
lives under `src/glot_backend/system`.

## Feature layout

A feature may use the following structure:

```text
src/glot_backend/<feature>/
├── domain/                 Business workflows and decisions
├── effect/
│   ├── algebra.gleam       Effect types and trace names
│   ├── effect.gleam        Program constructors
│   └── interpreter.gleam   Effect dispatch to ports
├── ports.gleam             Optional bundle of feature dependencies
├── ports/                   Individual dependency interfaces
├── adapter/                 Infrastructure implementations of ports
└── sql/                     Feature-owned Parrot SQL sources
```

Small features do not need every directory or a ports bundle. The structure
should reflect actual boundaries rather than create empty layers.

The intended dependency flow is:

```text
domain workflows → effect API → effect algebra
                                  ↓
                           effect interpreter → ports ← adapters
                                                        ↑
                                              application composition
```

- Domain workflows call effect APIs and remain independent of concrete
  infrastructure.
- Effect algebras describe required operations. Effect interpreters execute
  those operations through ports.
- Ports define the interfaces a feature needs. Adapters implement them for
  PostgreSQL, external services, caches, or tests.
- Composition code constructs adapters and supplies them to interpreters.

## Features with subfeatures

When a feature contains several related effect algebras, the feature root owns
their integration with the global program:

- `effect/algebra.gleam` combines subfeature effects into one feature effect.
- `effect/effect.gleam` is the only feature module that constructs the global
  `program_types` variant.
- `effect/interpreter.gleam` dispatches the combined effect to subinterpreters.
- `ports.gleam` bundles the dependencies accepted by the root interpreter.
- The root effect algebra combines subfeature trace names and delegates their
  string conversion to the owning subfeature algebra.

Auth, job, and logging are the reference implementations. Adding an operation
inside one of these features should require changes only in the owning
subfeature and its feature-root boundary. It should not add another global DB
effect, global trace variant, or individual dependency to the system
interpreter.

## Composition boundaries

Global composition is intentionally centralized:

- `system/effect/program_types.gleam` defines the closed set of application and
  database feature effects.
- `system/effect/db_effect.gleam` maps database feature effects.
- `system/effect/db_interpreter.gleam` delegates database effects to feature
  interpreters.
- `system/effect/effect_trace.gleam` delegates trace naming to feature
  algebras.
- `system/effect/database_ports.gleam` contains database-backed feature
  dependencies.
- `system/effect/service_ports.gleam` and `system/effect/system_ports.gleam`
  compose the complete runtime dependencies.

Adding an entirely new feature requires updating these composition roots.
Adding a subfeature or operation to an existing bundled feature should not.

## Effect interpreter measurements

Effect interpreters should use `system/effect/measured_interpreter.gleam` for
the standard operation, continuation, and trace-measurement lifecycle. Choose
the helper according to the operation's semantics:

- `run` measures an operation and passes its returned value unchanged to the
  effect continuation. A returned `Result` remains a value for the effect
  program to handle.
- `run_or_fail` measures an operation returning `Result`, passes a successful
  value to the effect continuation, and maps a failure directly to the
  application error surface without invoking the continuation.
- `run_with_kind` is for operations whose `EffectKind` is known only after
  execution, such as a lookup classified by its cache outcome.
- `run_with_state` is for operations that update `program_state.State` before
  continuing, such as collecting structured log fields.

At call sites, keep the operation and effect continuation as the first two
positional arguments. Pass error mapping, trace metadata, interpreter state,
and the interpreter continuation with labels so their roles remain explicit.

Keep feature-specific decisions and port composition in the feature
interpreter or a small local helper. Pass that operation to the measurement
helper rather than moving business behavior into the shared module.

Transaction interpretation is intentionally different. It owns its timing so
the transaction trace can include nested effect measurements and whether the
transaction rolled back. Do not route that aggregate lifecycle through the
ordinary measurement helpers.

## Database boundary

SQL sources live with their feature but are generated together into
`src/glot_backend/sql.gleam` by `../run_parrot.sh`. Generated query and row
types stay in the database layer. Convert SQL rows into domain types at the
program/handler or adapter boundary before returning them to domain code.

Domain modules must never import `glot_backend/sql`.

## Tests

Tests use the same ports as production code. Test adapters live under
`test/support`, and default test ports should fail on unexpected calls. A test
enables or replaces only the feature dependencies it exercises.

After backend changes, run:

```sh
cd glot_backend
gleam test
```
