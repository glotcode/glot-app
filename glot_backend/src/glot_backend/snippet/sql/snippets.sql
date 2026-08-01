-- name: GetSnippetById :one
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE snippets.id = $1;

-- name: GetSnippetBySlug :one
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE snippets.slug = $1;

-- name: GetSnippetBySlugForUpdate :one
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE snippets.slug = $1
FOR UPDATE OF snippets;

-- name: GetAdminSnippetBySlug :one
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE snippets.slug = $1;

-- name: ListSnippetsAfter :many
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE
  (
    cardinality(sqlc.arg(visibilities)::text[]) = 0
    OR snippets.visibility = ANY(sqlc.arg(visibilities)::text[])
  )
  AND (
    cardinality(sqlc.arg(usernames)::text[]) = 0
    OR users.username = ANY(sqlc.arg(usernames)::text[])
  )
  AND (
    cardinality(sqlc.arg(user_ids)::uuid[]) = 0
    OR users.id = ANY(sqlc.arg(user_ids)::uuid[])
  )
  AND NOT users.id = ANY(sqlc.arg(skip_user_ids)::uuid[])
  AND (
    sqlc.narg(after_slug)::text IS NULL
    OR snippets.slug < sqlc.narg(after_slug)::text
  )
ORDER BY snippets.slug DESC
LIMIT sqlc.arg(page_limit);

-- name: ListSnippetsBefore :many
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE
  (
    cardinality(sqlc.arg(visibilities)::text[]) = 0
    OR snippets.visibility = ANY(sqlc.arg(visibilities)::text[])
  )
  AND (
    cardinality(sqlc.arg(usernames)::text[]) = 0
    OR users.username = ANY(sqlc.arg(usernames)::text[])
  )
  AND (
    cardinality(sqlc.arg(user_ids)::uuid[]) = 0
    OR users.id = ANY(sqlc.arg(user_ids)::uuid[])
  )
  AND NOT users.id = ANY(sqlc.arg(skip_user_ids)::uuid[])
  AND (
    sqlc.narg(before_slug)::text IS NULL
    OR snippets.slug > sqlc.narg(before_slug)::text
  )
ORDER BY snippets.slug ASC
LIMIT sqlc.arg(page_limit);

-- name: ListAdminSnippetsAfter :many
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE
  (
    sqlc.narg(username)::text IS NULL
    OR users.username = sqlc.narg(username)::text
  )
  AND
  (
    sqlc.narg(after_slug)::text IS NULL
    OR snippets.slug < sqlc.narg(after_slug)::text
  )
ORDER BY snippets.slug DESC
LIMIT sqlc.arg(page_limit);

-- name: ListAdminSnippetsBefore :many
SELECT
  snippets.id,
  snippets.slug,
  snippets.language,
  snippets.title,
  snippets.visibility,
  snippets.stdin,
  snippets.run_instructions,
  snippets.files,
  snippets.created_at,
  snippets.updated_at,
  users.id AS user_id,
  users.account_id AS user_account_id,
  users.email AS user_email,
  users.username AS user_username,
  users.role AS user_role,
  users.last_login_at AS user_last_login_at,
  users.created_at AS user_created_at,
  users.updated_at AS user_updated_at
FROM snippets
INNER JOIN users ON users.id = snippets.user_id
WHERE
  (
    sqlc.narg(username)::text IS NULL
    OR users.username = sqlc.narg(username)::text
  )
  AND
  (
    sqlc.narg(before_slug)::text IS NULL
    OR snippets.slug > sqlc.narg(before_slug)::text
  )
ORDER BY snippets.slug ASC
LIMIT sqlc.arg(page_limit);

-- name: InsertSnippet :exec
INSERT INTO snippets (id, slug, user_id, language, title, visibility, stdin, run_instructions, files, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);

-- name: UpdateSnippet :exec
UPDATE snippets SET slug = $1, user_id = $2, language = $3, title = $4, visibility = $5, stdin = $6, run_instructions = $7, files = $8, created_at = $9, updated_at = $10 WHERE id = $11;

-- name: DeleteSnippet :exec
DELETE FROM snippets WHERE id = $1;

-- name: DeleteSnippetsByAccountId :exec
DELETE FROM snippets
WHERE user_id IN (
  SELECT id
  FROM users
  WHERE account_id = $1
);
