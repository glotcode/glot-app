ALTER TABLE snippets
  ADD COLUMN spam_decision TEXT NULL,
  ADD COLUMN spam_confidence INTEGER NULL,
  ADD COLUMN spam_reason_code TEXT NULL,
  ADD COLUMN spam_classified_at TIMESTAMPTZ NULL,
  ADD COLUMN spam_classification_attempts INTEGER DEFAULT 0,
  ADD COLUMN spam_classification_last_error TEXT,
  ADD COLUMN spam_classification_failed_at TIMESTAMPTZ;

CREATE INDEX idx_snippets_spam_classification_candidates
  ON snippets (updated_at DESC, id DESC)
  WHERE spam_decision IS NULL
    AND spam_classification_failed_at IS NULL;

CREATE INDEX idx_snippets_spam_classified_at
  ON snippets (spam_classified_at DESC)
  WHERE spam_classified_at IS NOT NULL;

CREATE INDEX idx_snippets_spam_classification_failed_at
  ON snippets (spam_classification_failed_at DESC)
  WHERE spam_classification_failed_at IS NOT NULL;
