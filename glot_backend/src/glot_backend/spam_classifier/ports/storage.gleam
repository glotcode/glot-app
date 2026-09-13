import gleam/option.{type Option}
import glot_backend/spam_classifier/model/fingerprint.{type StoredFingerprint}
import glot_backend/system/effect/error.{type Error}
import youid/uuid.{type Uuid}

pub type Storage {
  Storage(
    store: fn(StoredFingerprint) -> Result(Bool, Error),
    candidates: fn(String, List(String), Uuid) ->
      Result(List(fingerprint.Candidate), Error),
    index_batch: fn(String) -> Result(fingerprint.IndexBatch, Error),
    commit_index_batch: fn(String, Int, Option(Uuid), List(StoredFingerprint)) ->
      Result(Option(Int), Error),
  )
}
