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
import glot_frontend/public/editor/model.{
  type Editor, CustomRunInstructions, DefaultRunInstructions, Editor,
  MetadataDraft, NoRestoreDraft, RestoreDraftPending, SettingsDraft, Snippet,
  Workspace,
}
import glot_frontend/public/editor/run_instructions

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
  let run_instructions = case run_instructions_override {
    option.Some(instructions) -> instructions
    option.None ->
      run_instructions.default_run_instructions(draft.language, files)
  }

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
    workspace: Workspace(
      ..model.workspace,
      editor_external_revision: model.workspace.editor_external_revision + 1,
      selected_tab: selected_tab,
    ),
    entry_drafts: entry_drafts.initial(files, stdin, selected_tab),
    metadata_draft: MetadataDraft(..model.metadata_draft, title: draft.title),
    settings_draft: SettingsDraft(
      ..model.settings_draft,
      run_instructions_mode: case run_instructions_override {
        option.Some(_) -> CustomRunInstructions
        option.None -> DefaultRunInstructions
      },
      run_instructions: run_instructions.run_instructions_to_draft(
        run_instructions,
      ),
    ),
    restore_draft: NoRestoreDraft,
  )
}
