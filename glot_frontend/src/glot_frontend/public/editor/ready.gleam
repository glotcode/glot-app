import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/document
import glot_frontend/public/editor/entry_drafts
import glot_frontend/public/editor/metadata_draft
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/model.{
  type Editor, type Snippet, Editor, NoRestoreDraft, SaveDraft, Snippet,
}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/settings_draft
import glot_frontend/public/editor/workspace
import youid/uuid.{type Uuid}

pub fn new(
  language: language.Language,
  found: environment.Environment,
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
      is_runnable: option.None,
      files: [file],
      stdin: option.None,
      run_instructions_override: option.None,
    ),
    found,
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
  is_runnable is_runnable: option.Option(Bool),
  files files: List(snippet_model.File),
  stdin stdin: option.Option(String),
  run_instructions_override run_instructions_override: option.Option(
    language.RunInstructions,
  ),
  environment found: environment.Environment,
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
      is_runnable: is_runnable,
      files: files,
      stdin: stdin,
      run_instructions_override: run_instructions_override,
    ),
    found,
  )
}

fn build(snippet: Snippet, found: environment.Environment) -> Editor {
  let selected_tab = document.initial_tab(snippet.files, snippet.stdin)
  let editor_settings = found.settings

  Editor(
    snippet: snippet,
    workspace: workspace.build(
      snippet.files,
      snippet.stdin,
      selected_tab,
      snippet.language,
      found,
    ),
    entry_drafts: entry_drafts.initial(
      snippet.files,
      snippet.stdin,
      selected_tab,
    ),
    editor_settings: editor_settings,
    settings_draft: settings_draft.new(
      editor_settings,
      snippet.language,
      snippet.files,
      snippet.run_instructions_override,
    ),
    metadata_draft: metadata_draft.new(snippet.title, snippet.visibility),
    save_draft: SaveDraft(visibility: snippet.visibility),
    restore_draft: NoRestoreDraft,
    operations: operations.initial(),
  )
}
