import gleam/list
import gleam/option
import gleam/string
import glot_frontend/public/editor/files as editor_files
import glot_frontend/public/editor/model.{
  type Editor, AddFileEntry, AddStdinEntry, FileTab, StdinTab,
}

pub type AddEntryDecision {
  AddFile(filename: String)
  AddStdin
  AddEntryBlocked
}

pub type EditEntryDecision {
  RenameFile(index: Int, filename: String)
  EditEntryBlocked
}

pub type DeleteEntryDecision {
  DeleteFile(index: Int)
  DeleteStdin
  DeleteEntryBlocked
}

pub fn add_entry(model: Editor) -> AddEntryDecision {
  case model.entry_drafts.add.kind {
    AddFileEntry -> add_file(model)
    AddStdinEntry ->
      case model.snippet.stdin {
        option.None -> AddStdin
        option.Some(_) -> AddEntryBlocked
      }
  }
}

pub fn can_submit_add_entry(model: Editor) -> Bool {
  case add_entry(model) {
    AddFile(_) | AddStdin -> True
    AddEntryBlocked -> False
  }
}

pub fn edit_entry(model: Editor) -> EditEntryDecision {
  case model.workspace.selected_tab {
    StdinTab -> EditEntryBlocked
    FileTab(index) -> rename_file(model, index)
  }
}

pub fn can_submit_edit_entry(model: Editor) -> Bool {
  case edit_entry(model) {
    RenameFile(_, _) -> True
    EditEntryBlocked -> False
  }
}

pub fn delete_entry(model: Editor) -> DeleteEntryDecision {
  case model.workspace.selected_tab {
    FileTab(index) ->
      case
        valid_file_index(model, index) && list.length(model.snippet.files) > 1
      {
        True -> DeleteFile(index)
        False -> DeleteEntryBlocked
      }
    StdinTab ->
      case model.snippet.stdin {
        option.Some(_) -> DeleteStdin
        option.None -> DeleteEntryBlocked
      }
  }
}

pub fn can_delete_selected_file(model: Editor) -> Bool {
  case delete_entry(model) {
    DeleteFile(_) -> True
    DeleteStdin | DeleteEntryBlocked -> False
  }
}

pub fn add_stdin_message(stdin: option.Option(String)) -> String {
  case stdin {
    option.Some(_) -> "<stdin> already exists for this snippet."
    option.None -> "Add a dedicated <stdin> tab for runtime input."
  }
}

fn add_file(model: Editor) -> AddEntryDecision {
  let filename = string.trim(model.entry_drafts.add.filename)
  case
    editor_files.valid_name(filename)
    && !editor_files.name_exists(model.snippet.files, filename)
  {
    True -> AddFile(filename)
    False -> AddEntryBlocked
  }
}

fn rename_file(model: Editor, index: Int) -> EditEntryDecision {
  let filename = string.trim(model.entry_drafts.edit.filename)
  case
    valid_file_index(model, index)
    && editor_files.valid_name(filename)
    && !editor_files.name_exists_except(model.snippet.files, filename, index)
  {
    True -> RenameFile(index, filename)
    False -> EditEntryBlocked
  }
}

fn valid_file_index(model: Editor, index: Int) -> Bool {
  index >= 0 && index < list.length(model.snippet.files)
}
