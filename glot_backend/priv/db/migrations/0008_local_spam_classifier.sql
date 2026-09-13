-- Historical classifications deliberately keep NULL provenance.
ALTER TABLE snippets ADD COLUMN spam_explanation JSONB NULL;

CREATE TABLE spam_classifier_fingerprints (
  snippet_id UUID NOT NULL REFERENCES snippets(id) ON DELETE CASCADE,
  content_revision TIMESTAMPTZ NOT NULL,
  algorithm_version TEXT NOT NULL,
  token_count INTEGER NOT NULL CHECK (token_count BETWEEN 0 AND 16384),
  trigram_hashes INTEGER[] NOT NULL,
  signature INTEGER[] NOT NULL CHECK (cardinality(signature) = 64),
  independently_suspicious BOOLEAN NOT NULL,
  urls JSONB NOT NULL,
  indexed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (snippet_id, content_revision, algorithm_version)
);

CREATE TABLE spam_classifier_bands (
  snippet_id UUID NOT NULL,
  content_revision TIMESTAMPTZ NOT NULL,
  algorithm_version TEXT NOT NULL,
  band_number INTEGER NOT NULL CHECK (band_number BETWEEN 0 AND 15),
  band_value TEXT NOT NULL,
  PRIMARY KEY (snippet_id, content_revision, algorithm_version, band_number),
  FOREIGN KEY (snippet_id, content_revision, algorithm_version)
    REFERENCES spam_classifier_fingerprints ON DELETE CASCADE
);

CREATE INDEX spam_classifier_band_lookup
  ON spam_classifier_bands (algorithm_version, band_value);

