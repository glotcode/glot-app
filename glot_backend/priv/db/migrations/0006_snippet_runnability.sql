ALTER TABLE snippets
  ADD COLUMN is_runnable BOOLEAN NULL,
  ADD COLUMN runnability_checked_at TIMESTAMPTZ NULL,
  ADD COLUMN runnability_check_attempts INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN runnability_check_last_error TEXT NULL,
  ADD COLUMN runnability_check_failed_at TIMESTAMPTZ NULL;

CREATE INDEX idx_snippets_runnability_check_candidates
  ON snippets (updated_at DESC, id DESC)
  WHERE is_runnable IS NULL
    AND runnability_check_failed_at IS NULL;

CREATE INDEX idx_snippets_runnability_checked_at
  ON snippets (runnability_checked_at DESC)
  WHERE runnability_checked_at IS NOT NULL;

CREATE INDEX idx_snippets_runnability_check_failed_at
  ON snippets (runnability_check_failed_at DESC)
  WHERE runnability_check_failed_at IS NOT NULL;

INSERT INTO job_queues (name, created_at, updated_at)
VALUES ('snippet_runnability', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO job_queue_slots (queue_name, slot_number)
VALUES ('snippet_runnability', 1);
