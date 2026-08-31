import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/settings
import glot_frontend/ui/delayed_loading
import youid/uuid.{type Uuid}

pub type Model {
  Lifecycle(lifecycle.Model)
  Ready(Editor)
}

pub type Editor {
  Editor(
    snippet: Snippet,
    workspace: Workspace,
    entry_drafts: EntryDrafts,
    editor_settings: settings.EditorSettings,
    settings_draft: SettingsDraft,
    metadata_draft: MetadataDraft,
    save_draft: SaveDraft,
    restore_draft: RestoreDraftState,
    operations: operations.Operations,
  )
}

pub type Snippet {
  Snippet(
    slug: option.Option(String),
    owner_user_id: option.Option(Uuid),
    owner_username: option.Option(String),
    title: String,
    language: language.Language,
    visibility: snippet_model.Visibility,
    created_at: option.Option(Timestamp),
    updated_at: option.Option(Timestamp),
    is_runnable: option.Option(Bool),
    files: List(snippet_model.File),
    stdin: option.Option(String),
    run_instructions_override: option.Option(language.RunInstructions),
  )
}

pub type Workspace {
  Workspace(
    editor_revision: Int,
    editor_external_revision: Int,
    selected_tab: EditorTab,
  )
}

pub type EntryDrafts {
  EntryDrafts(add: AddEntryDraft, edit: EditEntryDraft)
}

pub type AddEntryDraft {
  AddEntryDraft(kind: AddEntryKind, filename: String)
}

pub type EditEntryDraft {
  EditEntryDraft(filename: String)
}

pub type SettingsDraft {
  SettingsDraft(
    editor_settings: settings.EditorSettings,
    run_instructions_mode: RunInstructionsMode,
    run_instructions: RunInstructionsDraft,
  )
}

pub type MetadataDraft {
  MetadataDraft(title: String, visibility: snippet_model.Visibility)
}

pub type SaveDraft {
  SaveDraft(visibility: snippet_model.Visibility)
}

pub type RestoreDraftState {
  NoRestoreDraft
  RestoreDraftPending(draft.StoredEditorDraft)
}

pub type RunInstructionsDraft {
  RunInstructionsDraft(build_commands_text: String, run_command: String)
}

pub type RunInstructionsMode {
  DefaultRunInstructions
  CustomRunInstructions
}

pub type EditorTab {
  FileTab(Int)
  StdinTab
}

pub fn is_presentable(model: Model) -> Bool {
  case model {
    Ready(_) -> True
    Lifecycle(state) ->
      case state {
        lifecycle.UnsupportedLanguage(_) | lifecycle.LoadError(_) -> True
        lifecycle.LoadingSnippet(_, _, loading_indicator) ->
          delayed_loading.is_visible(loading_indicator)
        lifecycle.Initializing(_) -> False
      }
  }
}

pub type AddEntryKind {
  AddFileEntry
  AddStdinEntry
}
