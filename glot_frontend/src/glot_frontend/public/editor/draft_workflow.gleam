import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_frontend/public/editor/command
import glot_frontend/public/editor/document
import glot_frontend/public/editor/draft as editor_draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/draft_policy
import glot_frontend/public/editor/entry_drafts
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{type RestoreDraftMsg}
import glot_frontend/public/editor/metadata_draft
import glot_frontend/public/editor/model.{
  type Editor, Editor, NoRestoreDraft, RestoreDraftPending, Snippet,
}
import glot_frontend/public/editor/settings_draft
import glot_frontend/public/editor/workspace

pub fn apply_loaded_draft(
  model: Editor,
  slug: String,
  updated_at: Timestamp,
  stored: option.Option(editor_draft.StoredEditorDraft),
) -> #(Editor, command.Command(RestoreDraftMsg)) {
  case model.snippet.slug, model.snippet.updated_at {
    option.Some(current_slug), option.Some(current_updated_at)
      if current_slug == slug && current_updated_at == updated_at
    ->
      case stored {
        option.Some(stored) ->
          case
            draft_policy.is_newer_than_saved_snippet(
              stored.saved_at_ms,
              updated_at,
            )
          {
            True -> #(
              Editor(..model, restore_draft: RestoreDraftPending(stored)),
              command.OpenDialogNextFrame(ids.restore_draft_dialog),
            )
            False -> #(
              model,
              command.ClearDraft(draft_persistence.ExistingSnippet(slug)),
            )
          }
        option.None -> #(model, command.none())
      }
    _, _ -> #(model, command.none())
  }
}

pub fn apply_editor_draft(
  model: Editor,
  draft: editor_draft.EditorDraft,
) -> Editor {
  let files = draft.files
  let stdin = draft.stdin
  let selected_tab = document.initial_tab(files, stdin)
  let run_instructions_override = draft.run_instructions_override

  Editor(
    ..model,
    snippet: Snippet(
      ..model.snippet,
      title: draft.title,
      language: draft.language,
      files: files,
      stdin: stdin,
      run_instructions_override: run_instructions_override,
    ),
    workspace: workspace.replace_documents(
        current: model.workspace,
        files: files,
        stdin: stdin,
        selected_tab: selected_tab,
      )
      |> workspace.set_language(draft.language),
    entry_drafts: entry_drafts.initial(files, stdin, selected_tab),
    metadata_draft: metadata_draft.new(draft.title, model.snippet.visibility),
    settings_draft: settings_draft.new(
      model.editor_settings,
      draft.language,
      files,
      run_instructions_override,
    ),
    restore_draft: NoRestoreDraft,
  )
}
