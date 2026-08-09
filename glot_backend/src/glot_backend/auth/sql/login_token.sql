-- name: ListLoginTokensByEmail :many
SELECT id, email, token, attempt_count, created_at, used_at
FROM login_tokens
WHERE email = $1
  AND used_at IS NULL
  AND created_at >= $2
ORDER BY created_at DESC, id DESC
LIMIT $3
FOR UPDATE;

-- name: InsertLoginToken :exec
INSERT INTO login_tokens (id, email, token, attempt_count, created_at, used_at) VALUES ($1, $2, $3, $4, $5, $6);

-- name: UpdateLoginToken :exec
UPDATE login_tokens SET email = $1, token = $2, attempt_count = $3, created_at = $4, used_at = $5 WHERE id = $6;

-- name: DeleteLoginTokensBefore :exec
DELETE FROM login_tokens
WHERE created_at < $1;

-- name: InvalidateLoginTokensByEmails :exec
UPDATE login_tokens
SET used_at = $1
WHERE used_at IS NULL
  AND (
    email = sqlc.arg(old_email)::text
    OR email = sqlc.arg(new_email)::text
  );
