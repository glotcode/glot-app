import gleam/option
import gleam/time/timestamp
import glot_core/auth/user_dto
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/api/response
import glot_frontend/public/editor/draft
import youid/uuid

pub fn owner_id() -> uuid.Uuid {
  id("00000000-0000-4000-8000-000000000010")
}

pub fn other_user_id() -> uuid.Uuid {
  id("00000000-0000-4000-8000-000000000011")
}

pub fn snippet(slug: String, source: String) -> snippet_dto.SnippetResponse {
  snippet_with(
    slug:,
    owner: owner_id(),
    title: "Editor fixture",
    visibility: snippet_model.Unlisted,
    files: [snippet_model.File("main.js", source)],
    stdin: "",
    run_instructions: option.None,
  )
}

pub fn snippet_with(
  slug slug: String,
  owner owner: uuid.Uuid,
  title title: String,
  visibility visibility: snippet_model.Visibility,
  files files: List(snippet_model.File),
  stdin stdin: String,
  run_instructions run_instructions: option.Option(language.RunInstructions),
) -> snippet_dto.SnippetResponse {
  snippet_dto.SnippetResponse(
    slug:,
    user: user_dto.UserResponse(id: owner, username: "fixture-owner"),
    data: snippet_dto.SnippetData(
      title:,
      language: language.JavaScript,
      visibility:,
      stdin:,
      run_instructions:,
      files:,
    ),
    created_at: timestamp.from_unix_seconds(100),
    updated_at: timestamp.from_unix_seconds(200),
    is_runnable: option.None,
  )
}

pub fn updated(
  original: snippet_dto.SnippetResponse,
  data: snippet_dto.SnippetData,
) -> snippet_dto.SnippetResponse {
  snippet_dto.SnippetResponse(
    ..original,
    data:,
    updated_at: timestamp.from_unix_seconds(300),
  )
}

pub fn successful_run(
  stdout stdout: String,
  stderr stderr: String,
  error error: String,
) -> response.Response(run.RunResult) {
  response.Success(
    Ok(run.SuccessfulRun(duration: 1_000_000, stdout:, stderr:, error:)),
  )
}

pub fn failed_run(message: String) -> response.Response(run.RunResult) {
  response.Success(Error(run.FailedRun(message:)))
}

pub fn stored_draft(
  saved_at_ms saved_at_ms: Int,
  title title: String,
  files files: List(snippet_model.File),
  stdin stdin: option.Option(String),
  run_instructions run_instructions: option.Option(language.RunInstructions),
) -> draft.StoredEditorDraft {
  draft.StoredEditorDraft(
    saved_at_ms:,
    draft: draft.EditorDraft(
      title:,
      language: language.JavaScript,
      files:,
      stdin:,
      run_instructions_override: run_instructions,
    ),
  )
}

pub fn api_failure(message: String) -> response.Response(value) {
  response.ApiFailure(response.Error(
    code: "fixture",
    message:,
    request_id: id("00000000-0000-4000-8000-000000000012"),
  ))
}

fn id(value: String) -> uuid.Uuid {
  let assert Ok(value) = uuid.from_string(value)
  value
}
