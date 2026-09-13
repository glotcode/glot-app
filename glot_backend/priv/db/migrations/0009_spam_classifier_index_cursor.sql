CREATE TABLE spam_classifier_index_progress (
  algorithm_version TEXT PRIMARY KEY,
  after_snippet_id UUID,
  generation BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- The cursor is a position, not a reference: deleting a snippet must not reset it.
