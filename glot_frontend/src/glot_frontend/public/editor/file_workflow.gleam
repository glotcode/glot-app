import gleam/list
import gleam/option
import gleam/string
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/entry_drafts
import glot_frontend/public/editor/files as editor_files
import glot_frontend/public/editor/model.{
  type Editor, AddFileEntry, AddStdinEntry, Editor, EntryDrafts, FileTab,
  Snippet, StdinTab, Workspace,
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
  case model.entry_drafts.add.kind {
    AddFileEntry -> add_file_entry(model)
    AddStdinEntry -> add_stdin_entry(model)
  }
}

pub fn add_file_entry(model: Editor) -> option.Option(Editor) {
  let filename = string.trim(model.entry_drafts.add.filename)
  case
    !editor_files.valid_name(filename)
    || editor_files.name_exists(model.snippet.files, filename)
  {
    True -> option.None
    False -> {
      let next_index = list.length(model.snippet.files)
      let next_file = snippet_model.File(name: filename, content: "")
      option.Some(
        Editor(
          ..model,
          snippet: Snippet(
            ..model.snippet,
            files: list.append(model.snippet.files, [next_file]),
          ),
          workspace: Workspace(
            ..model.workspace,
            selected_tab: FileTab(next_index),
            editor_external_revision: model.workspace.editor_external_revision
              + 1,
          ),
          entry_drafts: EntryDrafts(
            add: entry_drafts.add(model.snippet.stdin),
            edit: entry_drafts.edit(
              list.append(model.snippet.files, [next_file]),
              FileTab(next_index),
            ),
          ),
        ),
      )
    }
  }
}

pub fn add_stdin_entry(model: Editor) -> option.Option(Editor) {
  case model.snippet.stdin {
    option.Some(_) -> option.None
    option.None ->
      option.Some(
        Editor(
          ..model,
          snippet: Snippet(..model.snippet, stdin: option.Some("")),
          workspace: Workspace(
            ..model.workspace,
            selected_tab: StdinTab,
            editor_external_revision: model.workspace.editor_external_revision
              + 1,
          ),
          entry_drafts: EntryDrafts(
            add: entry_drafts.add(option.Some("")),
            edit: entry_drafts.edit(model.snippet.files, StdinTab),
          ),
        ),
      )
  }
}

pub fn rename_selected_file(model: Editor) -> option.Option(Editor) {
  case model.workspace.selected_tab {
    StdinTab -> option.None
    FileTab(index) -> {
      let filename = string.trim(model.entry_drafts.edit.filename)
      case
        !editor_files.valid_name(filename)
        || editor_files.name_exists_except(model.snippet.files, filename, index)
      {
        True -> option.None
        False -> {
          let files =
            editor_files.rename_at(model.snippet.files, index, filename)
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
  }
}

pub fn delete_selected_entry(model: Editor) -> option.Option(Editor) {
  case model.workspace.selected_tab {
    StdinTab ->
      option.Some(
        Editor(
          ..model,
          snippet: Snippet(..model.snippet, stdin: option.None),
          workspace: Workspace(
            ..model.workspace,
            selected_tab: FileTab(0),
            editor_external_revision: model.workspace.editor_external_revision
              + 1,
          ),
          entry_drafts: EntryDrafts(
            add: entry_drafts.add(option.None),
            edit: entry_drafts.edit(model.snippet.files, FileTab(0)),
          ),
        ),
      )

    FileTab(index) ->
      case list.length(model.snippet.files) > 1 {
        False -> option.None
        True -> {
          let next_files = editor_files.remove_at(model.snippet.files, index)
          let next_tab = case index >= list.length(next_files) {
            True -> FileTab(list.length(next_files) - 1)
            False -> FileTab(index)
          }

          option.Some(
            Editor(
              ..model,
              snippet: Snippet(..model.snippet, files: next_files),
              workspace: Workspace(
                ..model.workspace,
                selected_tab: next_tab,
                editor_external_revision: model.workspace.editor_external_revision
                  + 1,
              ),
              entry_drafts: EntryDrafts(
                ..model.entry_drafts,
                edit: entry_drafts.edit(next_files, next_tab),
              ),
            ),
          )
        }
      }
  }
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
