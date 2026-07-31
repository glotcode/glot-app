import gleam/option
import gleeunit
import glot_core/language
import glot_core/route
import glot_frontend/app/public_page_managed
import glot_frontend/app/public_page_message
import glot_frontend/app/public_page_state
import glot_frontend/app/runtime
import glot_frontend/public/editor/message as editor_message
import glot_frontend/public/editor/model as editor_model
import support/editor_scenario

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn routes_owned_by_the_other_application_initialize_empty_test() {
  let #(model, _) =
    public_page_managed.init(
      route.Admin(route.AdminHome),
      runtime.LoadingSession,
    )

  assert model == public_page_state.Empty
}

pub fn editor_metadata_changes_follow_committed_state_not_message_names_test() {
  let initial = existing_editor()
  let draft_changed =
    update_editor(
      initial,
      editor_message.Editor(
        editor_message.Metadata(editor_message.TitleDraftChanged("Renamed")),
      ),
    )

  assert !draft_changed.metadata_changed

  let submitted =
    update_editor(
      draft_changed.model,
      editor_message.Editor(editor_message.Metadata(
        editor_message.EditMetadataSubmitted,
      )),
    )

  assert submitted.metadata_changed

  let source_changed =
    update_editor(
      initial,
      editor_message.Editor(
        editor_message.Execution(editor_message.SourceCodeChanged(
          "new source",
          1,
        )),
      ),
    )

  assert !source_changed.metadata_changed
}

pub fn editor_metadata_detects_indirect_changes_to_the_projection_test() {
  let filename_changed =
    update_editor(
      existing_editor(),
      editor_message.Editor(
        editor_message.File(editor_message.AddEntryFilenameChanged("second.js")),
      ),
    )

  assert !filename_changed.metadata_changed

  let file_added =
    update_editor(
      filename_changed.model,
      editor_message.Editor(editor_message.File(
        editor_message.AddEntrySubmitted,
      )),
    )

  assert file_added.metadata_changed
}

fn existing_editor() -> public_page_state.Model {
  let assert editor_model.Ready(editor) =
    editor_scenario.new_editor(language.JavaScript)
  public_page_state.Editor(editor_model.Ready(
    editor_model.Editor(
      ..editor,
      snippet: editor_model.Snippet(
        ..editor.snippet,
        slug: option.Some("metadata-fixture"),
      ),
    ),
  ))
}

fn update_editor(
  model: public_page_state.Model,
  msg: editor_message.Msg,
) -> public_page_managed.Transition {
  let assert option.Some(transition) =
    public_page_managed.update(
      model,
      public_page_message.EditorPageMsg(msg),
      runtime.LoadingSession,
    )
  transition
}
