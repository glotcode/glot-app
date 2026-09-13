-- name: ListSpamReview :many
SELECT
  snippets.manual_verdict,
  snippets.manual_reviewer_id,
  snippets.manual_reviewed_at,
  snippets.manual_review_version,
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
  snippets.spam_explanation,
  snippets.is_runnable,
  snippets.runnability_checked_at,
  snippets.runnability_check_attempts,
  snippets.runnability_check_last_error,
  snippets.runnability_check_failed_at,
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
WHERE (sqlc.arg(decision)::text = 'all'
    OR (sqlc.arg(decision) = 'flagged' AND snippets.spam_decision IN ('review', 'block'))
    OR (sqlc.arg(decision) = 'unclassified' AND snippets.spam_decision IS NULL)
    OR snippets.spam_decision = sqlc.arg(decision))
  AND (sqlc.narg(reason)::text IS NULL OR snippets.spam_reason_code = sqlc.narg(reason))
  AND (sqlc.narg(confidence_min)::int IS NULL OR snippets.spam_confidence >= sqlc.narg(confidence_min))
  AND (sqlc.narg(confidence_max)::int IS NULL OR snippets.spam_confidence <= sqlc.narg(confidence_max))
  AND (sqlc.arg(manual)::text = 'all'
    OR (sqlc.arg(manual) = 'unreviewed' AND snippets.manual_verdict IS NULL)
    OR snippets.manual_verdict = sqlc.arg(manual))
  AND (sqlc.narg(username)::text IS NULL OR users.username = sqlc.narg(username))
  AND (sqlc.narg(language)::text IS NULL OR snippets.language = sqlc.narg(language))
  AND (sqlc.narg(cursor)::text IS NULL
    OR (sqlc.arg(backwards)::boolean AND (snippets.slug > sqlc.narg(cursor) OR (sqlc.arg(inclusive)::boolean AND snippets.slug = sqlc.narg(cursor))))
    OR (NOT sqlc.arg(backwards)::boolean AND (snippets.slug < sqlc.narg(cursor) OR (sqlc.arg(inclusive)::boolean AND snippets.slug = sqlc.narg(cursor)))))
  AND (sqlc.narg(focus)::text IS NULL OR snippets.slug = sqlc.narg(focus))
ORDER BY
  CASE WHEN sqlc.arg(backwards)::boolean THEN snippets.slug END ASC,
  CASE WHEN NOT sqlc.arg(backwards)::boolean THEN snippets.slug END DESC
LIMIT sqlc.arg(page_limit);

-- name: SaveManualReview :one
UPDATE snippets
SET manual_verdict = $2,
    manual_reviewer_id = $3,
    manual_reviewed_at = $4,
    manual_review_version = manual_review_version + 1
WHERE slug = $1
  AND manual_review_version = $5
  AND updated_at = $6
RETURNING manual_verdict, manual_reviewer_id, manual_reviewed_at, manual_review_version;
