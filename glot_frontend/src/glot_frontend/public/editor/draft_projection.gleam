import gleam/option
import glot_core/language
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/model.{type Editor}

pub fn value(model: Editor) -> draft.EditorDraft {
  draft.EditorDraft(
    title: model.snippet.title,
    language: model.snippet.language,
    files: model.snippet.files,
    stdin: model.snippet.stdin,
    run_instructions_override: model.snippet.run_instructions_override,
  )
}

pub fn target(model: Editor) -> draft_persistence.Target {
  case model.snippet.slug {
    option.None ->
      draft_persistence.NewSnippet(language.to_string(model.snippet.language))
    option.Some(slug) -> draft_persistence.ExistingSnippet(slug)
  }
}

pub fn write(model: Editor) -> draft_persistence.Write {
  draft_persistence.Write(target: target(model), value: value(model))
}
