import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/document
import glot_frontend/public/editor/entry_drafts
import glot_frontend/public/editor/execution
import glot_frontend/public/editor/model.{
  type Editor, type Snippet, Editor, MetadataDraft, NoRestoreDraft, Operations,
  SaveDraft, SettingsDraft, Snippet, Workspace,
}
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/settings
import youid/uuid.{type Uuid}

pub fn new(
  language: language.Language,
  editor_settings: settings.EditorSettings,
) -> Editor {
  let file = snippet_model.default_file(language)
  build(
    Snippet(
      slug: option.None,
      owner_user_id: option.None,
      owner_username: option.None,
      title: "Hello World",
      language: language,
      visibility: snippet_model.Unlisted,
      created_at: option.None,
      updated_at: option.None,
      files: [file],
      stdin: option.None,
      run_instructions_override: option.None,
    ),
    editor_settings,
  )
}

pub fn existing(
  slug slug: String,
  owner_user_id owner_user_id: option.Option(Uuid),
  owner_username owner_username: option.Option(String),
  title title: String,
  language language: language.Language,
  visibility visibility: snippet_model.Visibility,
  created_at created_at: option.Option(Timestamp),
  updated_at updated_at: Timestamp,
  files files: List(snippet_model.File),
  stdin stdin: option.Option(String),
  run_instructions_override run_instructions_override: option.Option(
    language.RunInstructions,
  ),
  editor_settings editor_settings: settings.EditorSettings,
) -> Editor {
  build(
    Snippet(
      slug: option.Some(slug),
      owner_user_id: owner_user_id,
      owner_username: owner_username,
      title: title,
      language: language,
      visibility: visibility,
      created_at: created_at,
      updated_at: option.Some(updated_at),
      files: files,
      stdin: stdin,
      run_instructions_override: run_instructions_override,
    ),
    editor_settings,
  )
}

fn build(snippet: Snippet, editor_settings: settings.EditorSettings) -> Editor {
  let selected_tab = document.initial_tab(snippet.files, snippet.stdin)
  let effective_run_instructions = case snippet.run_instructions_override {
    option.Some(instructions) -> instructions
    option.None ->
      run_instructions.default_run_instructions(snippet.language, snippet.files)
  }

  Editor(
    snippet: snippet,
    workspace: Workspace(
      editor_revision: 0,
      editor_external_revision: 0,
      selected_tab: selected_tab,
    ),
    entry_drafts: entry_drafts.initial(
      snippet.files,
      snippet.stdin,
      selected_tab,
    ),
    editor_settings: editor_settings,
    settings_draft: SettingsDraft(
      editor_settings: editor_settings,
      run_instructions_mode: run_instructions.run_instructions_mode_from_override(
        snippet.run_instructions_override,
      ),
      run_instructions: run_instructions.run_instructions_to_draft(
        effective_run_instructions,
      ),
    ),
    metadata_draft: MetadataDraft(
      title: snippet.title,
      visibility: snippet.visibility,
    ),
    save_draft: SaveDraft(visibility: snippet.visibility),
    restore_draft: NoRestoreDraft,
    operations: Operations(
      version_info: option.None,
      run_generation: 0,
      run_state: execution.Idle,
      save_generation: 0,
      save_state: execution.SaveIdle,
    ),
  )
}
