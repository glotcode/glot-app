import gleam/list
import gleam/option
import gleam/string
import glot_frontend/public/editor/files as editor_files
import glot_frontend/public/editor/model.{
  type Editor, AddFileEntry, AddStdinEntry, FileTab, StdinTab,
}

pub fn can_submit_add_entry(model: Editor) -> Bool {
  case model.entry_drafts.add.kind {
    AddFileEntry -> {
      let filename = string.trim(model.entry_drafts.add.filename)
      editor_files.valid_name(filename)
      && !editor_files.name_exists(model.snippet.files, filename)
    }

    AddStdinEntry -> model.snippet.stdin == option.None
  }
}

pub fn can_submit_edit_entry(model: Editor) -> Bool {
  case model.workspace.selected_tab {
    StdinTab -> False
    FileTab(index) -> {
      let filename = string.trim(model.entry_drafts.edit.filename)
      editor_files.valid_name(filename)
      && !editor_files.name_exists_except(model.snippet.files, filename, index)
    }
  }
}

pub fn can_delete_selected_file(model: Editor) -> Bool {
  case model.workspace.selected_tab {
    FileTab(_) -> list.length(model.snippet.files) > 1
    StdinTab -> False
  }
}

pub fn add_stdin_message(stdin: option.Option(String)) -> String {
  case stdin {
    option.Some(_) -> "<stdin> already exists for this snippet."
    option.None -> "Add a dedicated <stdin> tab for runtime input."
  }
}
