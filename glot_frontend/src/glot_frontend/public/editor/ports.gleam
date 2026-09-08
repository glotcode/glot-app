import gleam/option
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/public/editor/code_editor/ports as code_editor_ports
import glot_frontend/public/editor/draft
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/environment
import glot_frontend/public/editor/settings
import lustre/effect.{type Effect}

/// Runtime capabilities required by the editor command interpreter. Production
/// supplies browser-backed ports; tests interpret commands as data instead.
pub type Ports(msg) {
  Ports(
    load_environment: fn(fn(String, environment.Environment) -> msg) ->
      Effect(msg),
    load_draft: fn(
      draft_persistence.Target,
      fn(option.Option(draft.StoredEditorDraft)) -> msg,
    ) -> Effect(msg),
    get_snippet: fn(
      snippet_dto.GetSnippetRequest,
      fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
    ) -> Effect(msg),
    run_code: fn(run.RunRequest, fn(response.Response(run.RunResult)) -> msg) ->
      Effect(msg),
    cancel_run: fn() -> Effect(msg),
    get_language_version: fn(
      run.GetLanguageVersionRequest,
      fn(response.Response(run.RunResult)) -> msg,
    ) -> Effect(msg),
    create_snippet: fn(
      snippet_dto.CreateSnippetRequest,
      fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
    ) -> Effect(msg),
    update_snippet: fn(
      snippet_dto.UpdateSnippetRequest,
      fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
    ) -> Effect(msg),
    save_draft: fn(draft_persistence.Write) -> Effect(msg),
    clear_draft: fn(draft_persistence.Target) -> Effect(msg),
    save_settings: fn(settings.EditorSettings) -> Effect(msg),
    open_dialog: fn(String) -> Effect(msg),
    open_dialog_next_frame: fn(String) -> Effect(msg),
    close_dialog: fn(String) -> Effect(msg),
    focus: fn(String) -> Effect(msg),
    blur: fn(String) -> Effect(msg),
    navigate: fn(String) -> Effect(msg),
    schedule: fn(Int, msg) -> Effect(msg),
    code_editor: code_editor_ports.Ports(msg),
  )
}
