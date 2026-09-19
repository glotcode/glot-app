-- Band rows only exist for neighbor-eligible fingerprints (token_count >= 20).
-- Shorter snippets never pass the similarity threshold, and near-empty ones
-- share a degenerate signature that made every lookup scan the same hot bands.
DELETE FROM spam_classifier_bands b
USING spam_classifier_fingerprints f
WHERE f.snippet_id = b.snippet_id
  AND f.content_revision = b.content_revision
  AND f.algorithm_version = b.algorithm_version
  AND f.token_count < 20;
