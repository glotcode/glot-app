import gleam/option
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/files
import glot_frontend/public/editor/model.{
  type AddEntryKind, type EditorTab, AddFileEntry, FileTab, StdinTab,
}

pub fn initial_tab(
  files: List(snippet_model.File),
  stdin: option.Option(String),
) -> EditorTab {
  case files {
    [_first, ..] -> FileTab(0)
    [] ->
      case stdin {
        option.Some(_) -> StdinTab
        option.None -> FileTab(0)
      }
  }
}

pub fn default_add_entry_kind(_stdin: option.Option(String)) -> AddEntryKind {
  AddFileEntry
}

pub fn default_file_name(
  files_list: List(snippet_model.File),
  tab: EditorTab,
) -> String {
  case tab {
    FileTab(index) -> files.name_at(files_list, index)
    StdinTab -> ""
  }
}

pub fn selected_content(
  files_list: List(snippet_model.File),
  stdin: option.Option(String),
  tab: EditorTab,
) -> String {
  case tab {
    FileTab(index) -> files.content_at(files_list, index)
    StdinTab ->
      case stdin {
        option.Some(content) -> content
        option.None -> ""
      }
  }
}
