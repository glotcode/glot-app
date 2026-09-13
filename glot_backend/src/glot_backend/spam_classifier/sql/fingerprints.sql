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
WHERE s.id > COALESCE(sqlc.narg(after_snippet_id)::uuid, '00000000-0000-0000-0000-000000000000'::uuid)
AND NOT EXISTS (
  SELECT 1 FROM spam_classifier_fingerprints f
  WHERE f.snippet_id = s.id AND f.content_revision = s.updated_at
    AND f.algorithm_version = sqlc.arg(algorithm_version)::text
)
ORDER BY s.id
LIMIT 100;

-- name: GetClassifierIndexCursor :one
INSERT INTO spam_classifier_index_progress (algorithm_version)
VALUES (sqlc.arg(algorithm_version)::text)
ON CONFLICT (algorithm_version) DO UPDATE
SET algorithm_version = EXCLUDED.algorithm_version
RETURNING after_snippet_id, generation;

-- name: CommitClassifierIndexBatch :one
WITH progress AS MATERIALIZED (
  SELECT algorithm_version
  FROM spam_classifier_index_progress
  WHERE algorithm_version = sqlc.arg(algorithm_version)::text
    AND generation = sqlc.arg(expected_generation)::bigint
  FOR UPDATE
), input AS MATERIALIZED (
  SELECT (entry->>'snippet_id')::uuid AS snippet_id,
    (entry->>'content_revision')::timestamptz AS content_revision,
    (entry->>'token_count')::int AS token_count,
    ARRAY(SELECT jsonb_array_elements_text(entry->'trigram_hashes'))::int[] AS trigram_hashes,
    ARRAY(SELECT jsonb_array_elements_text(entry->'signature'))::int[] AS signature,
    (entry->>'independently_suspicious')::boolean AS independently_suspicious,
    entry->'urls' AS urls,
    ARRAY(SELECT jsonb_array_elements_text(entry->'bands'))::text[] AS bands
  FROM jsonb_array_elements(sqlc.arg(fingerprints)::jsonb) AS entry
  WHERE EXISTS (SELECT 1 FROM progress)
), current_snippets AS MATERIALIZED (
  SELECT s.id, s.updated_at
  FROM snippets s
  JOIN input i ON i.snippet_id = s.id AND i.content_revision = s.updated_at
  ORDER BY s.id
  FOR UPDATE OF s
), stored AS (
  INSERT INTO spam_classifier_fingerprints
    (snippet_id, content_revision, algorithm_version, token_count,
     trigram_hashes, signature, independently_suspicious, urls)
  SELECT i.snippet_id, i.content_revision, sqlc.arg(algorithm_version),
    i.token_count, i.trigram_hashes, i.signature, i.independently_suspicious, i.urls
  FROM input i JOIN current_snippets s
    ON s.id = i.snippet_id AND s.updated_at = i.content_revision
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
  FROM stored JOIN input i ON i.snippet_id = stored.snippet_id
  CROSS JOIN unnest(i.bands) WITH ORDINALITY AS band(value, ordinality)
  ON CONFLICT (snippet_id, content_revision, algorithm_version, band_number)
  DO UPDATE SET band_value = EXCLUDED.band_value
), advanced AS (
  UPDATE spam_classifier_index_progress p
  SET after_snippet_id = sqlc.narg(after_snippet_id)::uuid,
    generation = p.generation + 1, updated_at = CURRENT_TIMESTAMP
  FROM progress WHERE p.algorithm_version = progress.algorithm_version
  RETURNING p.algorithm_version
)
SELECT EXISTS(SELECT 1 FROM advanced)::boolean AS applied,
  (SELECT count(*) FROM stored)::int AS stored_count;
