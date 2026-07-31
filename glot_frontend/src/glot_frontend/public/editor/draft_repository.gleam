import gleam/option
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence

pub type Storage {
  Storage(
    read: fn(String) -> option.Option(String),
    write: fn(String, String) -> Bool,
    remove: fn(String) -> Bool,
    now_milliseconds: fn() -> Int,
  )
}

pub fn load(
  key: draft_persistence.Target,
  using storage: Storage,
) -> option.Option(draft.StoredEditorDraft) {
  let storage_key = draft_persistence.storage_key(key)
  case
    draft_persistence.read(
      storage.read(storage_key),
      storage.now_milliseconds(),
    )
  {
    draft_persistence.NoDraft -> option.None
    draft_persistence.UseDraft(stored) -> option.Some(stored)
    draft_persistence.RemoveStoredDraft -> {
      let _ = storage.remove(storage_key)
      option.None
    }
  }
}

pub fn save(
  key: draft_persistence.Target,
  value: draft.EditorDraft,
  using storage: Storage,
) -> Bool {
  storage.write(
    draft_persistence.storage_key(key),
    draft_persistence.encode(value, storage.now_milliseconds()),
  )
}

pub fn clear(key: draft_persistence.Target, using storage: Storage) -> Bool {
  storage.remove(draft_persistence.storage_key(key))
}
