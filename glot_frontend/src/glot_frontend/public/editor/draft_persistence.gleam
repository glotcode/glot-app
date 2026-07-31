import gleam/json
import gleam/option
import glot_frontend/public/editor/draft

pub type Target {
  NewSnippet(language_slug: String)
  ExistingSnippet(slug: String)
}

pub type Write {
  Write(target: Target, value: draft.EditorDraft)
}

pub type ReadDecision {
  NoDraft
  UseDraft(draft.StoredEditorDraft)
  RemoveStoredDraft
}

pub fn storage_key(target: Target) -> String {
  case target {
    NewSnippet(language_slug) -> "glot.editor.draft.new." <> language_slug
    ExistingSnippet(slug) -> "glot.editor.draft.snippet." <> slug
  }
}

pub fn read(raw: option.Option(String), now_milliseconds: Int) -> ReadDecision {
  case raw {
    option.None -> NoDraft
    option.Some(value) ->
      case json.parse(value, draft.stored_decoder()) {
        Error(_) -> RemoveStoredDraft
        Ok(stored) ->
          case draft.is_expired(stored.saved_at_ms, now_milliseconds) {
            True -> RemoveStoredDraft
            False -> UseDraft(stored)
          }
      }
  }
}

pub fn encode(value: draft.EditorDraft, saved_at_ms: Int) -> String {
  json.object([
    #("savedAtMs", json.int(saved_at_ms)),
    #("data", draft.encode(value)),
  ])
  |> json.to_string
}
