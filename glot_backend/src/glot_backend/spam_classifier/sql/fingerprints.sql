-- name: StoreClassifierFingerprint :one
WITH current_snippet AS (
  SELECT id FROM snippets
  WHERE id = sqlc.arg(snippet_id)::uuid AND updated_at = sqlc.arg(content_revision)::timestamptz
  FOR UPDATE
), stored AS (
  INSERT INTO spam_classifier_fingerprints
    (snippet_id, content_revision, algorithm_version, token_count,
     trigram_hashes, signature, independently_suspicious, urls)
  SELECT id, sqlc.arg(content_revision), sqlc.arg(algorithm_version)::text, sqlc.arg(token_count)::int, sqlc.arg(trigram_hashes)::int[], sqlc.arg(signature)::int[], sqlc.arg(independently_suspicious)::boolean, sqlc.arg(urls)::jsonb
  FROM current_snippet
  ON CONFLICT (snippet_id, content_revision, algorithm_version)
  DO UPDATE SET token_count = EXCLUDED.token_count,
    trigram_hashes = EXCLUDED.trigram_hashes, signature = EXCLUDED.signature,
    independently_suspicious = EXCLUDED.independently_suspicious,
    urls = EXCLUDED.urls, indexed_at = CURRENT_TIMESTAMP
  RETURNING snippet_id, content_revision, algorithm_version
), bands AS (
  INSERT INTO spam_classifier_bands
    (snippet_id, content_revision, algorithm_version, band_number, band_value)
  SELECT stored.snippet_id, stored.content_revision, stored.algorithm_version,
    (band.ordinality - 1)::int, band.value
  FROM stored CROSS JOIN unnest(sqlc.arg(bands)::text[]) WITH ORDINALITY AS band(value, ordinality)
  ON CONFLICT (snippet_id, content_revision, algorithm_version, band_number)
  DO UPDATE SET band_value = EXCLUDED.band_value
)
SELECT EXISTS(SELECT 1 FROM stored)::boolean AS stored;

-- name: FindClassifierNeighbors :many
SELECT f.snippet_id, f.content_revision, s.slug, f.token_count,
  f.trigram_hashes, f.signature, f.independently_suspicious,
  count(*)::int AS matching_bands
FROM spam_classifier_bands b
JOIN spam_classifier_fingerprints f USING (snippet_id, content_revision, algorithm_version)
JOIN snippets s ON s.id = f.snippet_id AND s.updated_at = f.content_revision
WHERE b.algorithm_version = sqlc.arg(algorithm_version)::text
  AND b.band_value = ANY(sqlc.arg(bands)::text[])
  AND b.snippet_id <> sqlc.arg(snippet_id)::uuid
  AND f.token_count >= 20
GROUP BY f.snippet_id, f.content_revision, f.algorithm_version, s.slug
ORDER BY matching_bands DESC, f.content_revision DESC, f.snippet_id DESC
LIMIT 200;

-- name: ListClassifierIndexBatch :many
SELECT s.id, s.slug, s.user_id, s.language, s.title, s.visibility, s.stdin,
  s.run_instructions, s.files, s.created_at, s.updated_at
FROM snippets s
WHERE NOT EXISTS (
  SELECT 1 FROM spam_classifier_fingerprints f
  WHERE f.snippet_id = s.id AND f.content_revision = s.updated_at
    AND f.algorithm_version = sqlc.arg(algorithm_version)::text
)
ORDER BY s.id
LIMIT 100;
