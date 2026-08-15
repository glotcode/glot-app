INSERT INTO job_type_policies (
  job_type, queue_name, max_attempts, timeout_seconds,
  base_backoff_seconds, max_backoff_seconds, created_at, updated_at
)
VALUES (
  'classify_snippet', 'spam_classifier', 10, 3600,
  30, 900, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
ON CONFLICT (job_type) DO UPDATE
SET queue_name = EXCLUDED.queue_name,
    max_attempts = EXCLUDED.max_attempts,
    timeout_seconds = EXCLUDED.timeout_seconds,
    base_backoff_seconds = EXCLUDED.base_backoff_seconds,
    max_backoff_seconds = EXCLUDED.max_backoff_seconds,
    updated_at = EXCLUDED.updated_at;

INSERT INTO periodic_jobs (
  id, job_type, payload, interval_seconds, enabled, next_run_at,
  last_enqueued_at, last_enqueue_error, created_at, updated_at
)
VALUES (
  uuidv4(), 'classify_snippet', NULL, 60, TRUE, CURRENT_TIMESTAMP,
  NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
ON CONFLICT (job_type) DO NOTHING;
