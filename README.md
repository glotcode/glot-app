# Glot

Glot is a Gleam web application for running code and sharing snippets. This
repository contains the backend, browser frontend, and the domain code shared
between them.

## Repository layout

- `glot_backend` — Erlang-target Gleam application, HTTP server, workers,
  PostgreSQL adapters, migrations, and startup seeds.
- `glot_frontend` — JavaScript-target Gleam application and browser assets,
  built with Lustre and Vite.
- `glot_core` — domain types and helpers shared by the backend and frontend.
- `glot_web` — shared Lustre presentation used by server-side and browser
  rendering; it depends on `glot_core`, never the reverse.

The backend is organized by feature. See
[Backend architecture](glot_backend/ARCHITECTURE.md) for its dependency rules,
effect boundaries, ports, adapters, and SQL organization.

## Prerequisites

- Gleam and a compatible Erlang/OTP installation
- Node.js and npm
- Docker with Docker Compose
- `watchexec` for the development watchers

## Local setup

Install the frontend dependencies:

```sh
cd glot_frontend
npm install
cd ..
```

Start a fresh local PostgreSQL instance:

```sh
./reset_db.sh
```

Build the frontend and start the backend:

```sh
./run_backend_cycle.sh
```

The backend listens on <http://localhost:3000> by default. At startup it runs
the migrations in `glot_backend/priv/db/migrations`, followed by the seeds for
the current `APP_ENV` in `glot_backend/priv/db/seeds`.

For automatic restarts when backend or shared Gleam sources change, use:

```sh
./run_backend.sh
```

The watcher rebuilds the frontend into `glot_backend/priv/static` before each
backend restart.

## Frontend development

With the backend running, start the Vite development server in another
terminal:

```sh
./run_frontend.sh
```

Vite listens on <http://localhost:5173> by default and proxies `/api` requests
to the backend on port 3000.

To build the browser assets once:

```sh
./build_frontend.sh
```

## Database tools

Open a PostgreSQL shell for the local database:

```sh
./psql.sh
```

Regenerate `glot_backend/src/glot_backend/sql.gleam` from the feature-local SQL
sources:

```sh
./run_parrot.sh
```

Parrot connects to the local `glot` database, so PostgreSQL must be running and
the schema must be current. Change SQL source files under feature `sql/`
directories; do not edit the generated `sql.gleam` directly.

To print the most recently created development login token:

```sh
./print_login_token.sh
```

## Configuration

`run_backend_env.sh` supplies a complete development configuration. For a
manually configured backend process, these variables are required:

| Variable | Purpose |
| --- | --- |
| `APP_ENV` | Seed environment: `dev` or `prod` |
| `ENCRYPTION_KEY` | Key used to protect signed application data |
| `POSTGRES_HOST` | PostgreSQL hostname |
| `POSTGRES_PORT` | PostgreSQL port |
| `POSTGRES_DB` | Database name |
| `POSTGRES_USER` | Database user |
| `POSTGRES_PASS` | Database password |
| `POSTGRES_POOL_SIZE` | Connection pool size |

The backend defaults to `localhost:3000`. Override that with
`LISTENING_ADDRESS` and `LISTENING_PORT`. `STATIC_BASE_PATH` can override the
directory served for frontend assets.

Outbound HTTP connections use independent pools for Docker-run and Cloudflare
email. They are controlled by dynamic app config entries in the `http_pool`
namespace and can be edited from the HTTP pools card on the admin App Config
page. When entries are absent, the backend uses these defaults:

| Key | Default | Purpose |
| --- | --- | --- |
| `docker_run_max_sessions` | `16` | Maximum persistent Docker-run connections |
| `cloudflare_email_max_sessions` | `4` | Maximum persistent Cloudflare email connections |
| `keep_alive_timeout_ms` | `120000` | Idle connection lifetime for both pools |

## Tests

Run the Gleam test suites from their application directories:

```sh
(cd glot_core && gleam test)
(cd glot_backend && gleam test)
(cd glot_frontend && gleam test)
```

Run the JavaScript custom-element tests with:

```sh
cd glot_frontend
npm run test:javascript
```

For backend changes, `glot_backend`'s full `gleam test` suite is the required
validation step.
