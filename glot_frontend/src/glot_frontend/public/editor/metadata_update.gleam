import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_projection
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/message.{
  type MetadataMsg, EditMetadataCancelled, EditMetadataClicked,
  EditMetadataDialogClosed, EditMetadataSubmitted,
  EditMetadataVisibilitySelected, TitleDraftChanged,
}
import glot_frontend/public/editor/metadata_draft
import glot_frontend/public/editor/model.{
  type Editor, Editor, MetadataDraft, Snippet,
}

pub fn update(
  model: Editor,
  msg: MetadataMsg,
) -> #(Editor, command.Command(MetadataMsg)) {
  case msg {
    EditMetadataClicked -> #(
      Editor(..model, metadata_draft: metadata_draft.from_editor(model)),
      command.OpenDialog(ids.edit_metadata_dialog),
    )

    TitleDraftChanged(title_draft) -> #(
      Editor(
        ..model,
        metadata_draft: MetadataDraft(
          ..model.metadata_draft,
          title: title_draft,
        ),
      ),
      command.none(),
    )

    EditMetadataVisibilitySelected(visibility) -> #(
      Editor(
        ..model,
        metadata_draft: MetadataDraft(
          ..model.metadata_draft,
          visibility: visibility,
        ),
      ),
      command.none(),
    )

    EditMetadataCancelled -> #(
      Editor(..model, metadata_draft: metadata_draft.from_editor(model)),
      command.CloseDialog(ids.edit_metadata_dialog),
    )

    EditMetadataSubmitted -> {
      let next_model =
        Editor(
          ..model,
          snippet: Snippet(
            ..model.snippet,
            title: model.metadata_draft.title,
            visibility: model.metadata_draft.visibility,
          ),
        )
      #(
        next_model,
        command.batch([
          command.CloseDialog(ids.edit_metadata_dialog),
          command.SaveDraft(draft_projection.write(next_model)),
        ]),
      )
    }

    EditMetadataDialogClosed -> #(
      Editor(..model, metadata_draft: metadata_draft.from_editor(model)),
      focus_editor(),
    )
  }
}

fn focus_editor() -> command.Command(msg) {
  command.Focus(ids.editor)
}
