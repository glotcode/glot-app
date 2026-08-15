CREATE TABLE job_queues (
  name TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

INSERT INTO job_queues (name, created_at, updated_at)
VALUES
  ('default', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('spam_classifier', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

CREATE TABLE job_queue_slots (
  queue_name TEXT NOT NULL REFERENCES job_queues(name) ON DELETE CASCADE,
  slot_number INTEGER NOT NULL CHECK (slot_number > 0),
  job_id UUID NULL REFERENCES jobs(id) ON DELETE SET NULL,
  lease_expires_at TIMESTAMPTZ NULL,
  PRIMARY KEY (queue_name, slot_number),
  UNIQUE (job_id)
);

INSERT INTO job_queue_slots (queue_name, slot_number)
-- Allow ordinary short jobs to run concurrently across app instances.
SELECT 'default', slot_number
FROM generate_series(1, 32) AS slot_number;

INSERT INTO job_queue_slots (queue_name, slot_number)
-- The classifier service only accepts one concurrent request cluster-wide.
VALUES ('spam_classifier', 1);

ALTER TABLE job_type_policies
  ADD COLUMN queue_name TEXT NOT NULL DEFAULT 'default'
    REFERENCES job_queues(name);

ALTER TABLE jobs
  ADD COLUMN queue_name TEXT NOT NULL DEFAULT 'default'
    REFERENCES job_queues(name),
  ADD COLUMN dedupe_key TEXT NULL;

CREATE INDEX idx_jobs_queue_status_run_at
  ON jobs(queue_name, status, run_at);

CREATE UNIQUE INDEX idx_jobs_active_dedupe_key
  ON jobs(dedupe_key)
  WHERE dedupe_key IS NOT NULL AND status IN ('pending', 'running');
