-- name: GetJobById :one
SELECT
  id,
  request_id,
  periodic_job_id,
  job_type,
  queue_name,
  dedupe_key,
  payload,
  status,
  attempts,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  run_at,
  started_at,
  lease_expires_at,
  completed_at,
  timed_out_at,
  last_error,
  created_at,
  updated_at
FROM jobs
WHERE id = $1;

-- name: GetNextJob :one
SELECT
  id,
  request_id,
  periodic_job_id,
  job_type,
  queue_name,
  dedupe_key,
  payload,
  status,
  attempts,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  run_at,
  started_at,
  lease_expires_at,
  completed_at,
  timed_out_at,
  last_error,
  created_at,
  updated_at
FROM jobs
WHERE jobs.status = @pending_status
  AND queue_name = @queue_name
  AND run_at <= @now
  AND started_at IS NULL
ORDER BY run_at ASC, created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- name: GetExpiredRunningJob :one
SELECT
  id,
  request_id,
  periodic_job_id,
  job_type,
  queue_name,
  dedupe_key,
  payload,
  status,
  attempts,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  run_at,
  started_at,
  lease_expires_at,
  completed_at,
  timed_out_at,
  last_error,
  created_at,
  updated_at
FROM jobs
WHERE jobs.status = @running_status
  AND queue_name = @queue_name
  AND lease_expires_at IS NOT NULL
  AND lease_expires_at <= @now
ORDER BY lease_expires_at ASC, created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- name: ListJobsAfter :many
SELECT
  id,
  request_id,
  periodic_job_id,
  job_type,
  queue_name,
  dedupe_key,
  payload,
  status,
  attempts,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  run_at,
  started_at,
  lease_expires_at,
  completed_at,
  timed_out_at,
  last_error,
  created_at,
  updated_at
FROM jobs
WHERE (
    cardinality(sqlc.arg(statuses)::text[]) = 0
    OR status = ANY(sqlc.arg(statuses)::text[])
  )
  AND (
    sqlc.narg(job_type)::text IS NULL
    OR job_type = sqlc.narg(job_type)::text
  )
  AND (
    sqlc.narg(periodic_job_id)::uuid IS NULL
    OR periodic_job_id = sqlc.narg(periodic_job_id)::uuid
  )
  AND (
    sqlc.narg(after_id)::uuid IS NULL
    OR id < sqlc.narg(after_id)::uuid
  )
ORDER BY id DESC
LIMIT sqlc.arg(page_limit);

-- name: ListJobsBefore :many
SELECT
  id,
  request_id,
  periodic_job_id,
  job_type,
  queue_name,
  dedupe_key,
  payload,
  status,
  attempts,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  run_at,
  started_at,
  lease_expires_at,
  completed_at,
  timed_out_at,
  last_error,
  created_at,
  updated_at
FROM jobs
WHERE (
    cardinality(sqlc.arg(statuses)::text[]) = 0
    OR status = ANY(sqlc.arg(statuses)::text[])
  )
  AND (
    sqlc.narg(job_type)::text IS NULL
    OR job_type = sqlc.narg(job_type)::text
  )
  AND (
    sqlc.narg(periodic_job_id)::uuid IS NULL
    OR periodic_job_id = sqlc.narg(periodic_job_id)::uuid
  )
  AND (
    sqlc.narg(before_id)::uuid IS NULL
    OR id > sqlc.narg(before_id)::uuid
  )
ORDER BY id ASC
LIMIT sqlc.arg(page_limit);

-- name: SummarizeJobs :one
SELECT
  COUNT(*)::int AS total_count,
  COUNT(*) FILTER (WHERE status = 'pending')::int AS pending_count,
  COUNT(*) FILTER (WHERE status = 'running')::int AS running_count,
  COUNT(*) FILTER (WHERE status = 'failed')::int AS failed_count,
  COUNT(*) FILTER (WHERE status = 'done')::int AS done_count,
  COUNT(*) FILTER (
    WHERE status = 'pending'
      AND run_at < @now
  )::int AS overdue_count
FROM jobs
WHERE (
    cardinality(sqlc.arg(statuses)::text[]) = 0
    OR status = ANY(sqlc.arg(statuses)::text[])
  )
  AND (
    sqlc.narg(job_type)::text IS NULL
    OR job_type = sqlc.narg(job_type)::text
  )
  AND (
    sqlc.narg(periodic_job_id)::uuid IS NULL
    OR periodic_job_id = sqlc.narg(periodic_job_id)::uuid
  );

-- name: GetNextPeriodicJob :one
SELECT
  id,
  job_type,
  payload,
  interval_seconds,
  enabled,
  next_run_at,
  last_enqueued_at,
  last_enqueue_error,
  created_at,
  updated_at
FROM periodic_jobs
WHERE enabled = TRUE
  AND next_run_at <= @now
ORDER BY next_run_at ASC, created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- name: ListPeriodicJobs :many
SELECT
  id,
  job_type,
  payload,
  interval_seconds,
  enabled,
  next_run_at,
  last_enqueued_at,
  last_enqueue_error,
  created_at,
  updated_at
FROM periodic_jobs
ORDER BY job_type ASC;

-- name: GetPeriodicJobById :one
SELECT
  id,
  job_type,
  payload,
  interval_seconds,
  enabled,
  next_run_at,
  last_enqueued_at,
  last_enqueue_error,
  created_at,
  updated_at
FROM periodic_jobs
WHERE id = $1;

-- name: GetPeriodicJobByIdForUpdate :one
SELECT
  id,
  job_type,
  payload,
  interval_seconds,
  enabled,
  next_run_at,
  last_enqueued_at,
  last_enqueue_error,
  created_at,
  updated_at
FROM periodic_jobs
WHERE id = $1
FOR UPDATE;

-- name: InsertJob :exec
INSERT INTO jobs (
  id,
  request_id,
  periodic_job_id,
  job_type,
  queue_name,
  dedupe_key,
  payload,
  status,
  attempts,
  max_attempts,
  timeout_seconds,
  base_backoff_seconds,
  max_backoff_seconds,
  run_at,
  started_at,
  lease_expires_at,
  completed_at,
  timed_out_at,
  last_error,
  created_at,
  updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
ON CONFLICT (dedupe_key)
  WHERE dedupe_key IS NOT NULL AND status IN ('pending', 'running')
DO NOTHING;

-- name: InsertPeriodicJob :exec
INSERT INTO periodic_jobs (
  id,
  job_type,
  payload,
  interval_seconds,
  enabled,
  next_run_at,
  last_enqueued_at,
  last_enqueue_error,
  created_at,
  updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);

-- name: InsertJobLog :exec
INSERT INTO job_log (id, request_id, job_id, job_type, attempt, created_at, duration_ns, info, warnings, debug, error, effects)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);

-- name: UpdateJob :exec
UPDATE jobs
SET request_id = $2,
    periodic_job_id = $3,
    job_type = $4,
    queue_name = $5,
    dedupe_key = $6,
    payload = $7,
    status = $8,
    attempts = $9,
    max_attempts = $10,
    timeout_seconds = $11,
    base_backoff_seconds = $12,
    max_backoff_seconds = $13,
    run_at = $14,
    started_at = $15,
    lease_expires_at = $16,
    completed_at = $17,
    timed_out_at = $18,
    last_error = $19,
    created_at = $20,
    updated_at = $21
WHERE id = $1
  -- Reject a late completion from an older attempt after recovery/reclaim.
  AND (
    (
      $8 = 'running'
      AND jobs.status = 'pending'
      AND jobs.attempts + 1 = $9
    )
    OR (
      $8 <> 'running'
      AND jobs.status = 'running'
      AND jobs.attempts = $9
    )
  );

-- name: ClaimJobQueueSlot :one
UPDATE job_queue_slots AS slots
SET job_id = @job_id,
    lease_expires_at = @lease_expires_at
WHERE (slots.queue_name, slots.slot_number) = (
  SELECT candidate.queue_name, candidate.slot_number
  FROM job_queue_slots AS candidate
  WHERE candidate.queue_name = @queue_name
    AND candidate.job_id IS NULL
  ORDER BY candidate.slot_number
  LIMIT 1
  FOR UPDATE SKIP LOCKED
)
RETURNING queue_name;

-- name: ReleaseJobQueueSlot :exec
UPDATE job_queue_slots
SET job_id = NULL,
    lease_expires_at = NULL
WHERE job_id = @job_id
  AND lease_expires_at = @lease_expires_at;

-- name: UpdatePeriodicJob :exec
UPDATE periodic_jobs
SET job_type = $2,
    payload = $3,
    interval_seconds = $4,
    enabled = $5,
    next_run_at = $6,
    last_enqueued_at = $7,
    last_enqueue_error = $8,
    created_at = $9,
    updated_at = $10
WHERE id = $1;

-- name: DeleteJob :exec
DELETE FROM jobs
WHERE id = $1;

-- name: DeleteBefore :exec
DELETE FROM jobs
WHERE completed_at IS NOT NULL
  AND completed_at < @before
  AND status = ANY(sqlc.arg(statuses)::text[]);

-- name: DeleteJobLogBefore :exec
DELETE FROM job_log
WHERE created_at < $1;
