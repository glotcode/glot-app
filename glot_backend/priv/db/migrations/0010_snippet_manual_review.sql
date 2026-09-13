ALTER TABLE snippets
  ADD COLUMN manual_verdict TEXT CHECK (manual_verdict IN ('spam', 'not_spam')),
  ADD COLUMN manual_reviewer_id UUID,
  ADD COLUMN manual_reviewed_at TIMESTAMPTZ,
  ADD COLUMN manual_review_version BIGINT NOT NULL DEFAULT 0
    CHECK (manual_review_version >= 0);

-- Reviewer identity is retained even if the reviewer account is later deleted.
CREATE INDEX idx_snippets_manual_review_queue ON snippets (slug DESC)
  WHERE manual_verdict IS NULL AND spam_decision IN ('review', 'block');
