import glot_backend/spam_classifier/ports/storage

pub fn defaults() -> storage.Storage {
  storage.Storage(
    store: fn(_) { panic as "unexpected fingerprint store" },
    candidates: fn(_, _, _) { panic as "unexpected fingerprint candidates" },
    commit_index_batch: fn(_, _, _, _) {
      panic as "unexpected fingerprint batch commit"
    },
    index_batch: fn(_) { panic as "unexpected fingerprint index batch" },
  )
}

// Explicit opt-in for tests that exercise classification without historical data.
pub fn empty_index() -> storage.Storage {
  storage.Storage(
    ..defaults(),
    store: fn(_) { Ok(True) },
    candidates: fn(_, _, _) { Ok([]) },
  )
}
