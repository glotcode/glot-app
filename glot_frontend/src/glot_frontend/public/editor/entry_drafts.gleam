import gleam/option
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/document
import glot_frontend/public/editor/model.{
  type AddEntryDraft, type EditEntryDraft, type EditorTab, type EntryDrafts,
  AddEntryDraft, EditEntryDraft, EntryDrafts,
}

pub fn initial(
  files: List(snippet_model.File),
  stdin: option.Option(String),
  selected_tab: EditorTab,
) -> EntryDrafts {
  EntryDrafts(add: add(stdin), edit: edit(files, selected_tab))
}

pub fn add(stdin: option.Option(String)) -> AddEntryDraft {
  AddEntryDraft(kind: document.default_add_entry_kind(stdin), filename: "")
}

pub fn edit(
  files: List(snippet_model.File),
  selected_tab: EditorTab,
) -> EditEntryDraft {
  EditEntryDraft(filename: document.default_file_name(files, selected_tab))
}
