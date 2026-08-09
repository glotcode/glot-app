-- name: ListEmailChangeTokensByUserId :many
SELECT id, user_id, old_email, new_email, token, attempt_count, created_at, used_at
FROM email_change_tokens
WHERE user_id = $1
  AND used_at IS NULL
  AND created_at >= $2
ORDER BY created_at DESC, id DESC
LIMIT $3;

-- name: ListEmailChangeTokensByUserIdForUpdate :many
SELECT id, user_id, old_email, new_email, token, attempt_count, created_at, used_at
FROM email_change_tokens
WHERE user_id = $1
  AND used_at IS NULL
  AND created_at >= $2
ORDER BY created_at DESC, id DESC
LIMIT $3
FOR UPDATE;

-- name: InsertEmailChangeToken :exec
INSERT INTO email_change_tokens (
  id, user_id, old_email, new_email, token, attempt_count, created_at, used_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8);

-- name: UpdateEmailChangeToken :exec
UPDATE email_change_tokens SET
  old_email = $1,
  new_email = $2,
  token = $3,
  attempt_count = $4,
  created_at = $5,
  used_at = $6
WHERE id = $7;

-- name: DeleteEmailChangeTokensBefore :exec
DELETE FROM email_change_tokens
WHERE created_at < $1;
