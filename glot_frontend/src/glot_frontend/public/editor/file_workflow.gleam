import gleam/list
import gleam/option
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/entry_drafts
import glot_frontend/public/editor/file_policy
import glot_frontend/public/editor/files as editor_files
import glot_frontend/public/editor/model.{
  type Editor, Editor, EntryDrafts, FileTab, Snippet, StdinTab, Workspace,
}

pub fn reset_add_entry_draft(model: Editor) -> Editor {
  Editor(
    ..model,
    entry_drafts: EntryDrafts(
      ..model.entry_drafts,
      add: entry_drafts.add(model.snippet.stdin),
    ),
  )
}

pub fn reset_edit_entry_draft(model: Editor) -> Editor {
  Editor(
    ..model,
    entry_drafts: EntryDrafts(
      ..model.entry_drafts,
      edit: entry_drafts.edit(model.snippet.files, model.workspace.selected_tab),
    ),
  )
}

pub fn add_entry(model: Editor) -> option.Option(Editor) {
  case file_policy.add_entry(model) {
    file_policy.AddFile(filename) -> option.Some(add_file(model, filename))
    file_policy.AddStdin -> option.Some(add_stdin(model))
    file_policy.AddEntryBlocked -> option.None
  }
}

fn add_file(model: Editor, filename: String) -> Editor {
  let next_index = list.length(model.snippet.files)
  let next_file = snippet_model.File(name: filename, content: "")
  let next_files = list.append(model.snippet.files, [next_file])
  Editor(
    ..model,
    snippet: Snippet(..model.snippet, files: next_files),
    workspace: Workspace(
      ..model.workspace,
      selected_tab: FileTab(next_index),
      editor_external_revision: model.workspace.editor_external_revision + 1,
    ),
    entry_drafts: EntryDrafts(
      add: entry_drafts.add(model.snippet.stdin),
      edit: entry_drafts.edit(next_files, FileTab(next_index)),
    ),
  )
}

fn add_stdin(model: Editor) -> Editor {
  Editor(
    ..model,
    snippet: Snippet(..model.snippet, stdin: option.Some("")),
    workspace: Workspace(
      ..model.workspace,
      selected_tab: StdinTab,
      editor_external_revision: model.workspace.editor_external_revision + 1,
    ),
    entry_drafts: EntryDrafts(
      add: entry_drafts.add(option.Some("")),
      edit: entry_drafts.edit(model.snippet.files, StdinTab),
    ),
  )
}

pub fn rename_selected_file(model: Editor) -> option.Option(Editor) {
  case file_policy.edit_entry(model) {
    file_policy.EditEntryBlocked -> option.None
    file_policy.RenameFile(index, filename) -> {
      let files = editor_files.rename_at(model.snippet.files, index, filename)
      option.Some(
        Editor(
          ..model,
          snippet: Snippet(..model.snippet, files: files),
          entry_drafts: EntryDrafts(
            ..model.entry_drafts,
            edit: entry_drafts.edit(files, model.workspace.selected_tab),
          ),
        ),
      )
    }
  }
}

pub fn delete_selected_entry(model: Editor) -> option.Option(Editor) {
  case file_policy.delete_entry(model) {
    file_policy.DeleteEntryBlocked -> option.None
    file_policy.DeleteStdin -> option.Some(delete_stdin(model))
    file_policy.DeleteFile(index) -> option.Some(delete_file(model, index))
  }
}

fn delete_stdin(model: Editor) -> Editor {
  Editor(
    ..model,
    snippet: Snippet(..model.snippet, stdin: option.None),
    workspace: Workspace(
      ..model.workspace,
      selected_tab: FileTab(0),
      editor_external_revision: model.workspace.editor_external_revision + 1,
    ),
    entry_drafts: EntryDrafts(
      add: entry_drafts.add(option.None),
      edit: entry_drafts.edit(model.snippet.files, FileTab(0)),
    ),
  )
}

fn delete_file(model: Editor, index: Int) -> Editor {
  let next_files = editor_files.remove_at(model.snippet.files, index)
  let next_tab = case index >= list.length(next_files) {
    True -> FileTab(list.length(next_files) - 1)
    False -> FileTab(index)
  }

  Editor(
    ..model,
    snippet: Snippet(..model.snippet, files: next_files),
    workspace: Workspace(
      ..model.workspace,
      selected_tab: next_tab,
      editor_external_revision: model.workspace.editor_external_revision + 1,
    ),
    entry_drafts: EntryDrafts(
      ..model.entry_drafts,
      edit: entry_drafts.edit(next_files, next_tab),
    ),
  )
}

pub fn update_selected_tab_content(model: Editor, content: String) -> Editor {
  case model.workspace.selected_tab {
    FileTab(index) ->
      Editor(
        ..model,
        snippet: Snippet(
          ..model.snippet,
          files: editor_files.update_content_at(
            model.snippet.files,
            index,
            content,
          ),
        ),
      )
    StdinTab ->
      Editor(
        ..model,
        snippet: Snippet(..model.snippet, stdin: option.Some(content)),
      )
  }
}
