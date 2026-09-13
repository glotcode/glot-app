import gleam/time/timestamp.{type Timestamp}
import glot_backend/spam_classifier/domain/similarity.{type Fingerprint}
import youid/uuid.{type Uuid}

pub type StoredFingerprint {
  StoredFingerprint(
    snippet_id: Uuid,
    revision: Timestamp,
    version: String,
    fingerprint: Fingerprint,
    independently_suspicious: Bool,
    urls: List(String),
  )
}

pub type Candidate {
  Candidate(
    snippet_id: Uuid,
    revision: Timestamp,
    slug: String,
    fingerprint: Fingerprint,
    independently_suspicious: Bool,
    matching_bands: Int,
  )
}

pub type IndexReport {
  IndexReport(scanned: Int, stored: Int, stale: Int)
}
