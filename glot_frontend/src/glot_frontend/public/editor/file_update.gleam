import gleam/option
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/entry_drafts
import glot_frontend/public/editor/file_workflow
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type FileMsg, AddEntryCancelled, AddEntryClicked, AddEntryDialogClosed,
  AddEntryFilenameChanged, AddEntryKindSelected, AddEntrySubmitted,
  EditEntryCancelled, EditEntryDeleted, EditEntryDialogClosed,
  EditEntryFilenameChanged, EditEntrySubmitted, SelectedTabActionClicked,
}
import glot_frontend/public/editor/model.{
  type Editor, AddEntryDraft, EditEntryDraft, Editor, EntryDrafts,
}

pub fn update(
  model: Editor,
  msg: FileMsg,
) -> #(Editor, command.Command(FileMsg)) {
  case msg {
    AddEntryClicked -> #(
      Editor(
        ..model,
        entry_drafts: EntryDrafts(
          ..model.entry_drafts,
          add: entry_drafts.add(model.snippet.stdin),
        ),
      ),
      command.OpenDialog(ids.add_entry_dialog),
    )

    AddEntryKindSelected(kind) -> #(
      Editor(
        ..model,
        entry_drafts: EntryDrafts(
          ..model.entry_drafts,
          add: AddEntryDraft(..model.entry_drafts.add, kind: kind),
        ),
      ),
      command.none(),
    )

    AddEntryFilenameChanged(filename) -> #(
      Editor(
        ..model,
        entry_drafts: EntryDrafts(
          ..model.entry_drafts,
          add: AddEntryDraft(..model.entry_drafts.add, filename: filename),
        ),
      ),
      command.none(),
    )

    AddEntryCancelled -> #(
      file_workflow.reset_add_entry_draft(model),
      command.CloseDialog(ids.add_entry_dialog),
    )

    AddEntrySubmitted -> {
      case file_workflow.add_entry(model) {
        option.Some(next_model) -> #(
          next_model,
          command.batch([
            command.CloseDialog(ids.add_entry_dialog),
            command.SaveDraft(draft_projection.write(next_model)),
          ]),
        )

        option.None -> #(model, command.none())
      }
    }

    AddEntryDialogClosed -> #(
      file_workflow.reset_add_entry_draft(model),
      focus_editor(),
    )

    SelectedTabActionClicked -> #(
      Editor(
        ..model,
        entry_drafts: EntryDrafts(
          ..model.entry_drafts,
          edit: entry_drafts.edit(
            model.snippet.files,
            model.workspace.selected_tab,
          ),
        ),
      ),
      command.OpenDialog(ids.edit_entry_dialog),
    )

    EditEntryFilenameChanged(filename) -> #(
      Editor(
        ..model,
        entry_drafts: EntryDrafts(
          ..model.entry_drafts,
          edit: EditEntryDraft(filename: filename),
        ),
      ),
      command.none(),
    )

    EditEntryCancelled -> #(
      file_workflow.reset_edit_entry_draft(model),
      command.CloseDialog(ids.edit_entry_dialog),
    )

    EditEntrySubmitted -> {
      case file_workflow.rename_selected_file(model) {
        option.Some(next_model) -> #(
          next_model,
          command.batch([
            command.CloseDialog(ids.edit_entry_dialog),
            command.SaveDraft(draft_projection.write(next_model)),
          ]),
        )

        option.None -> #(model, command.none())
      }
    }

    EditEntryDeleted -> {
      case file_workflow.delete_selected_entry(model) {
        option.Some(next_model) -> #(
          next_model,
          command.batch([
            command.CloseDialog(ids.edit_entry_dialog),
            command.SaveDraft(draft_projection.write(next_model)),
          ]),
        )

        option.None -> #(model, command.none())
      }
    }

    EditEntryDialogClosed -> #(
      file_workflow.reset_edit_entry_draft(model),
      focus_editor(),
    )
  }
}

fn focus_editor() -> command.Command(msg) {
  command.Focus(ids.editor)
}
