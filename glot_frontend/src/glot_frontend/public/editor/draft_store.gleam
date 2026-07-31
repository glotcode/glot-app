import gleam/option
import glot_frontend/platform/clock
import glot_frontend/platform/local_storage
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/draft_repository
import lustre/effect.{type Effect}

pub fn load(
  target: draft_persistence.Target,
) -> option.Option(draft.StoredEditorDraft) {
  draft_repository.load(target, using: production_storage())
}

pub fn save(write: draft_persistence.Write) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let draft_persistence.Write(target:, value:) = write
    let _ = draft_repository.save(target, value, using: production_storage())
    Nil
  })
}

pub fn clear(target: draft_persistence.Target) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let _ = draft_repository.clear(target, using: production_storage())
    Nil
  })
}

fn production_storage() -> draft_repository.Storage {
  draft_repository.Storage(
    read: local_storage.get,
    write: local_storage.set,
    remove: local_storage.remove,
    now_milliseconds: clock.now_milliseconds,
  )
}
