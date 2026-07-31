import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response as api_response
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/lifecycle.{type Target}
import glot_frontend/public/editor/model.{
  type AddEntryKind, type EditorTab, type RunStream, type SaveStream,
}
import glot_frontend/public/editor/settings
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/delayed_loading

pub type Msg {
  Lifecycle(LifecycleMsg)
  Editor(EditorMsg)
}

pub type EditorMsg {
  RestoreDraft(RestoreDraftMsg)
  Metadata(MetadataMsg)
  File(FileMsg)
  Settings(SettingsMsg)
  Save(SaveMsg)
  SnippetInfo(SnippetInfoMsg)
  Execution(ExecutionMsg)
}

pub type LifecycleMsg {
  EnvironmentLoaded(Target, String, settings.EditorSettings)
  SnippetLoaded(String, api_response.Response(snippet_dto.SnippetResponse))
  SnippetLoadingDelayElapsed(String, Generation(delayed_loading.Stream))
}

pub type RestoreDraftMsg {
  NewDraftLoaded(String, option.Option(draft.StoredEditorDraft))
  ExistingDraftLoaded(String, Timestamp, option.Option(draft.StoredEditorDraft))
  RestoreDraftAccepted
  RestoreDraftDeclined
  RestoreDraftClosed
}

pub type MetadataMsg {
  EditMetadataClicked
  TitleDraftChanged(String)
  EditMetadataVisibilitySelected(snippet_model.Visibility)
  EditMetadataCancelled
  EditMetadataSubmitted
  EditMetadataDialogClosed
}

pub type FileMsg {
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
}

pub type SettingsMsg {
  SettingsClicked
  KeyboardBindingsDraftSelected(settings.KeyboardBindings)
  RunInstructionsModeDraftChanged(String)
  RunInstructionsBuildCommandsDraftChanged(String)
  RunInstructionsRunCommandDraftChanged(String)
  SettingsCancelled
  SettingsSubmitted
  SettingsDialogClosed
}

pub type SaveMsg {
  SaveClicked
  SaveVisibilityDraftSelected(snippet_model.Visibility)
  SaveCancelled
  SaveConfirmed
  SaveDialogClosed
  SaveFinished(
    Generation(SaveStream),
    api_response.Response(snippet_dto.SnippetResponse),
  )
}

pub type SnippetInfoMsg {
  SnippetInfoClicked
  SnippetInfoDismissed
  SnippetInfoClosed
}

pub type ExecutionMsg {
  TabSelected(EditorTab)
  TabKeyPressed(EditorTab, String)
  SourceCodeChanged(String, Int)
  RunSubmitted
  RunFinished(Generation(RunStream), api_response.Response(run.RunResult))
  VersionRunFinished(language.Language, api_response.Response(run.RunResult))
}
