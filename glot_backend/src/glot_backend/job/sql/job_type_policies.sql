-- name: ListJobTypePolicies :many
SELECT
  job_type,
  queue_name,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  created_at,
  updated_at
FROM job_type_policies
ORDER BY job_type ASC;

-- name: GetJobTypePolicyByJobType :one
SELECT
  job_type,
  queue_name,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  created_at,
  updated_at
FROM job_type_policies
WHERE job_type = $1;

-- name: UpsertJobTypePolicy :exec
INSERT INTO job_type_policies (
  job_type,
  queue_name,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  created_at,
  updated_at
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
ON CONFLICT (job_type) DO UPDATE
SET queue_name = EXCLUDED.queue_name,
    max_attempts = EXCLUDED.max_attempts,
    timeout_seconds = EXCLUDED.timeout_seconds,
    base_backoff_seconds = EXCLUDED.base_backoff_seconds,
    max_backoff_seconds = EXCLUDED.max_backoff_seconds,
    updated_at = EXCLUDED.updated_at;
