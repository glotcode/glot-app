import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/model.{
  type AddEntryKind, type EditorTab, type InitTarget,
}
import glot_frontend/public/editor/settings

pub type Msg {
  EnvironmentLoaded(InitTarget, String, settings.EditorSettings)
  NewDraftLoaded(String, option.Option(draft.StoredEditorDraft))
  SnippetLoaded(String, api_response.Response(snippet_dto.SnippetResponse))
  SnippetLoadingDelayElapsed(String, Int)
  ExistingDraftLoaded(String, Timestamp, option.Option(draft.StoredEditorDraft))
  EditMetadataClicked
  TitleDraftChanged(String)
  EditMetadataVisibilitySelected(snippet_model.Visibility)
  EditMetadataCancelled
  EditMetadataSubmitted
  EditMetadataDialogClosed
  AddEntryClicked
  AddEntryKindSelected(AddEntryKind)
  AddEntryFilenameChanged(String)
  AddEntryCancelled
  AddEntrySubmitted
  AddEntryDialogClosed
  SelectedTabActionClicked
  EditEntryFilenameChanged(String)
  EditEntryCancelled
  EditEntrySubmitted
  EditEntryDeleted
  EditEntryDialogClosed
  SettingsClicked
  KeyboardBindingsDraftSelected(settings.KeyboardBindings)
  RunInstructionsModeDraftChanged(String)
  RunInstructionsBuildCommandsDraftChanged(String)
  RunInstructionsRunCommandDraftChanged(String)
  SettingsCancelled
  SettingsSubmitted
  SettingsDialogClosed
  SaveClicked
  SaveVisibilityDraftSelected(snippet_model.Visibility)
  SaveCancelled
  SaveConfirmed
  SaveDialogClosed
  RestoreDraftAccepted
  RestoreDraftDeclined
  RestoreDraftClosed
  SnippetInfoClicked
  SnippetInfoDismissed
  SnippetInfoClosed
  TabSelected(EditorTab)
  TabKeyPressed(EditorTab, String)
  SourceCodeChanged(String, Int)
  RunSubmitted
  RunFinished(Int, api_response.Response(run.RunResult))
  VersionRunFinished(language.Language, api_response.Response(run.RunResult))
  SaveFinished(Int, api_response.Response(snippet_dto.SnippetResponse))
}
