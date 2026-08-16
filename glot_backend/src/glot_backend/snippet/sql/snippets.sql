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
  snippets.spam_decision,
  snippets.spam_confidence,
  snippets.spam_reason_code,
  snippets.spam_classified_at,
  snippets.spam_classification_attempts,
  snippets.spam_classification_last_error,
  snippets.spam_classification_failed_at,
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
INNER JOIN accounts ON accounts.id = users.account_id
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
    cardinality(sqlc.arg(languages)::text[]) = 0
    OR snippets.language = ANY(sqlc.arg(languages)::text[])
  )
  AND (
    cardinality(sqlc.arg(user_ids)::uuid[]) = 0
    OR users.id = ANY(sqlc.arg(user_ids)::uuid[])
  )
  AND NOT users.id = ANY(sqlc.arg(skip_user_ids)::uuid[])
  AND (
    cardinality(sqlc.arg(account_states)::text[]) = 0
    OR accounts.account_state = ANY(sqlc.arg(account_states)::text[])
  )
  AND (
    sqlc.narg(user_created_before)::timestamptz IS NULL
    OR users.created_at < sqlc.narg(user_created_before)::timestamptz
  )
  AND lower(snippets.title) <> ALL(sqlc.arg(excluded_titles)::text[])
  AND snippets.language <> ALL(sqlc.arg(excluded_languages)::text[])
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
INNER JOIN accounts ON accounts.id = users.account_id
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
    cardinality(sqlc.arg(languages)::text[]) = 0
    OR snippets.language = ANY(sqlc.arg(languages)::text[])
  )
  AND (
    cardinality(sqlc.arg(user_ids)::uuid[]) = 0
    OR users.id = ANY(sqlc.arg(user_ids)::uuid[])
  )
  AND NOT users.id = ANY(sqlc.arg(skip_user_ids)::uuid[])
  AND (
    cardinality(sqlc.arg(account_states)::text[]) = 0
    OR accounts.account_state = ANY(sqlc.arg(account_states)::text[])
  )
  AND (
    sqlc.narg(user_created_before)::timestamptz IS NULL
    OR users.created_at < sqlc.narg(user_created_before)::timestamptz
  )
  AND lower(snippets.title) <> ALL(sqlc.arg(excluded_titles)::text[])
  AND snippets.language <> ALL(sqlc.arg(excluded_languages)::text[])
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
  AND (
    sqlc.narg(spam_classification)::text IS NULL
    OR (
      sqlc.narg(spam_classification)::text = 'unclassified'
      AND snippets.spam_decision IS NULL
    )
    OR snippets.spam_decision = sqlc.narg(spam_classification)::text
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
  AND (
    sqlc.narg(spam_classification)::text IS NULL
    OR (
      sqlc.narg(spam_classification)::text = 'unclassified'
      AND snippets.spam_decision IS NULL
    )
    OR snippets.spam_decision = sqlc.narg(spam_classification)::text
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
UPDATE snippets SET slug = $1, user_id = $2, language = $3, title = $4, visibility = $5, stdin = $6, run_instructions = $7, files = $8, created_at = $9, updated_at = $10, spam_decision = NULL, spam_confidence = NULL, spam_reason_code = NULL, spam_classified_at = NULL, spam_classification_attempts = 0, spam_classification_last_error = NULL, spam_classification_failed_at = NULL WHERE id = $11;

-- name: GetNewestUnclassifiedSnippet :one
SELECT id, slug, user_id, language, title, visibility, stdin, run_instructions, files, created_at, updated_at,
  COALESCE(spam_classification_attempts, 0)::int AS spam_classification_attempts
FROM snippets
WHERE spam_decision IS NULL
  AND spam_classification_failed_at IS NULL
ORDER BY updated_at DESC, id DESC
LIMIT 1;

-- name: StoreSpamClassification :exec
UPDATE snippets
SET spam_decision = $1,
    spam_confidence = $2,
    spam_reason_code = $3,
    spam_classified_at = $4,
    spam_classification_last_error = NULL,
    spam_classification_failed_at = NULL
WHERE id = $5
  AND updated_at = $6
  AND spam_decision IS NULL
  AND spam_classification_failed_at IS NULL;

-- name: UpdateSpamClassification :exec
-- Classification is operational metadata and must not change the snippet's updated_at.
UPDATE snippets
SET spam_decision = $1,
    spam_confidence = $2,
    spam_reason_code = $3,
    spam_classified_at = $4,
    spam_classification_attempts = COALESCE(spam_classification_attempts, 0) + 1,
    spam_classification_last_error = NULL,
    spam_classification_failed_at = NULL
WHERE id = $5
  AND updated_at = $6;

-- name: IncrementSpamClassificationAttempts :exec
UPDATE snippets
SET spam_classification_attempts = COALESCE(spam_classification_attempts, 0) + 1
WHERE id = $1
  AND updated_at = $2
  AND spam_decision IS NULL
  AND spam_classification_failed_at IS NULL;

-- name: StoreSpamClassificationFailure :exec
UPDATE snippets
SET spam_classification_last_error = $1,
    spam_classification_failed_at = $2
WHERE id = $3
  AND updated_at = $4
  AND spam_decision IS NULL
  AND spam_classification_failed_at IS NULL;

-- name: DeleteSnippet :exec
DELETE FROM snippets WHERE id = $1;

-- name: DeleteSnippetsByAccountId :exec
DELETE FROM snippets
WHERE user_id IN (
  SELECT id
  FROM users
  WHERE account_id = $1
);
