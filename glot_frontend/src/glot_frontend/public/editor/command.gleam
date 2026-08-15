import gleam/list
import gleam/option
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/settings

pub type Command(msg) {
  None
  Batch(List(Command(msg)))
  LoadEnvironment(fn(String, settings.EditorSettings) -> msg)
  LoadDraft(
    draft_persistence.Target,
    fn(option.Option(draft.StoredEditorDraft)) -> msg,
  )
  GetSnippet(
    snippet_dto.GetSnippetRequest,
    fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
  )
  RunCode(run.RunRequest, fn(response.Response(run.RunResult)) -> msg)
  CancelRun
  GetLanguageVersion(
    run.GetLanguageVersionRequest,
    fn(response.Response(run.RunResult)) -> msg,
  )
  CreateSnippet(
    snippet_dto.CreateSnippetRequest,
    fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
  )
  UpdateSnippet(
    snippet_dto.UpdateSnippetRequest,
    fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
  )
  SaveDraft(draft_persistence.Write)
  ClearDraft(draft_persistence.Target)
  SaveSettings(settings.EditorSettings)
  OpenDialog(String)
  OpenDialogNextFrame(String)
  CloseDialog(String)
  Focus(String)
  Blur(String)
  Navigate(String)
  Schedule(Int, msg)
}

pub fn none() -> Command(msg) {
  None
}

pub fn batch(commands: List(Command(msg))) -> Command(msg) {
  Batch(commands)
}

pub fn map(command: Command(a), transform: fn(a) -> b) -> Command(b) {
  case command {
    None -> None
    Batch(commands) ->
      Batch(list.map(commands, fn(item) { map(item, transform) }))
    LoadEnvironment(callback) ->
      LoadEnvironment(fn(raw, settings) { callback(raw, settings) |> transform })
    LoadDraft(target, callback) ->
      LoadDraft(target, fn(stored) { callback(stored) |> transform })
    GetSnippet(request, callback) ->
      GetSnippet(request, fn(result) { callback(result) |> transform })
    RunCode(request, callback) ->
      RunCode(request, fn(result) { callback(result) |> transform })
    CancelRun -> CancelRun
    GetLanguageVersion(request, callback) ->
      GetLanguageVersion(request, fn(result) { callback(result) |> transform })
    CreateSnippet(request, callback) ->
      CreateSnippet(request, fn(result) { callback(result) |> transform })
    UpdateSnippet(request, callback) ->
      UpdateSnippet(request, fn(result) { callback(result) |> transform })
    SaveDraft(write) -> SaveDraft(write)
    ClearDraft(target) -> ClearDraft(target)
    SaveSettings(settings) -> SaveSettings(settings)
    OpenDialog(id) -> OpenDialog(id)
    OpenDialogNextFrame(id) -> OpenDialogNextFrame(id)
    CloseDialog(id) -> CloseDialog(id)
    Focus(id) -> Focus(id)
    Blur(id) -> Blur(id)
    Navigate(path) -> Navigate(path)
    Schedule(delay, msg) -> Schedule(delay, transform(msg))
  }
}
