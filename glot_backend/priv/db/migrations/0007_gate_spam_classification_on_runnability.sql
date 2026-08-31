DROP INDEX idx_snippets_spam_classification_candidates;

CREATE INDEX idx_snippets_spam_classification_candidates
  ON snippets (updated_at DESC, id DESC)
  WHERE spam_decision IS NULL
    AND spam_classification_failed_at IS NULL
    AND is_runnable IS NOT NULL;
