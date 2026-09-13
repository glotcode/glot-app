# Spam review verification

Verified on 2026-09-13.

## Behavior and evidence

- `/admin/spam-review` is registered in the shared route codec, backend admin
  shell, managed admin router, breadcrumbs, and admin home navigation. The
  snippet directory remains available. `test/page/http_test.gleam` in the
  backend verifies the route serves the admin application.
- Core DTO tests cover manual metadata, guarded save requests, exact snippet
  references, action names, invalid verdicts, and negative versions.
- `glot_backend/test/manual_review_postgres.py` applies the startup migrations
  in a disposable schema and exercises the repository SQL. It checks default
  selection, combined filters, exact usernames/languages, confidence 0 and 100,
  missing metadata, both cursor directions, queue-boundary navigation,
  save/clear/undo, unchanged visibility/classification, and persistence through
  content edits and both automated classification writes. Separate connections
  verify that blocked review writes recheck the review version and content
  revision after a competing transaction commits.
- Backend domain tests verify anonymous and regular-user rejection, admin
  access, audit creation, returned reviewer/timestamp/version metadata, the
  one-item limit with cursor lookahead, and 409 conflicts without review audits.
- Frontend managed tests cover URL defaults, invalid bounds, independent draft
  field updates, obsolete reload responses, duplicate-save suppression,
  failure retention, save-and-advance, guarded Undo, and retention across
  cursor routes. The new managed boundary passes the dependency checker.
- `tests/browser/spam-review.spec.ts` uses the production admin application and
  API transport with controlled responses. All 15 cases pass across Chromium,
  Firefox, and WebKit. They cover escaped inline multi-file content, stdin/run
  instructions, keyboard activation, disabled saving controls, save/clear/undo,
  completion, Previous/Next, filters, refresh/history, loading/save failures,
  concurrent-review conflicts, and content changes before Undo.

## Commands

| Command | Result |
| --- | --- |
| `gleam test` in `glot_core` | 66 passed |
| `gleam test` in `glot_backend` | 287 passed |
| `gleam test` in `glot_web` | 14 passed |
| `python3 test/manual_review_postgres.py` in `glot_backend` | Passed |
| `npm test` in `glot_frontend` | Boundary/CSS checks, 584 Gleam tests, 30 JavaScript tests passed |
| `npm run build` in `glot_frontend` | Passed; existing Rollup/crypto and chunk-size warnings |
| `npm run test:browser` in `glot_frontend` | 192 passed, 11 skipped, 1 editor timing failure |
| `npm run test:browser -- editor-performance --project=firefox --grep "replace all"` | Passed on retry: 3,716 ms |
| `npm run test:browser -- spam-review` | 15 passed on the final implementation |

The full-suite failure was the existing Firefox 6,250-line replace-all timing
check: 5,003 ms against a 5,000 ms threshold. No editor implementation or test
threshold was changed. The skipped tests are existing environment/browser-gated
editor tests; no spam-review cases were skipped.

SQL was regenerated with `./run_parrot.sh`. Migration
`0010_snippet_manual_review.sql` adds independent nullable verdict/reviewer/time
fields and a nonnegative version initialized to zero. Undo uses the same API
mutation, the previous verdict, the latest saved version, and the displayed
content revision. It returns to an exact snippet reference in the URL; ordinary
navigation continues from that slug within the applied filters. Undo is kept
in memory while navigating within the review page and resets on a full reload
or when leaving the review page.
