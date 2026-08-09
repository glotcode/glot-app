import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/auth/user_dto
import glot_core/helpers/timestamp_helpers
import glot_core/language
import glot_core/pagination_model
import glot_core/snippet/snippet_model
import youid/uuid

pub type GetSnippetRequest {
  GetSnippetRequest(slug: String)
}

pub fn get_decoder() -> decode.Decoder(GetSnippetRequest) {
  use slug <- decode.field("slug", decode.string)
  decode.success(GetSnippetRequest(slug: slug))
}

pub type ListPublicSnippetsRequest {
  ListPublicSnippetsRequest(
    pagination: pagination_model.CursorPagination,
    usernames: List(String),
    languages: List(language.Language),
  )
}

pub type ListSessionSnippetsRequest {
  ListSessionSnippetsRequest(
    pagination: pagination_model.CursorPagination,
    languages: List(language.Language),
  )
}

pub fn list_public_decoder() -> decode.Decoder(ListPublicSnippetsRequest) {
  decode.then(pagination_model.request_decoder(), fn(pagination) {
    use usernames <- decode.field("usernames", decode.list(decode.string))
    use languages <- decode.field("languages", decode.list(language.decoder()))
    decode.success(ListPublicSnippetsRequest(
      pagination:,
      usernames:,
      languages:,
    ))
  })
}

pub fn list_session_decoder() -> decode.Decoder(ListSessionSnippetsRequest) {
  decode.then(pagination_model.request_decoder(), fn(pagination) {
    use languages <- decode.field("languages", decode.list(language.decoder()))
    decode.success(ListSessionSnippetsRequest(pagination:, languages:))
  })
}

pub type DeleteSnippetRequest {
  DeleteSnippetRequest(slug: String)
}

pub fn delete_decoder() -> decode.Decoder(DeleteSnippetRequest) {
  use slug <- decode.field("slug", decode.string)
  decode.success(DeleteSnippetRequest(slug: slug))
}

pub type CreateSnippetRequest {
  CreateSnippetRequest(data: SnippetData)
}

pub fn create_decoder() -> decode.Decoder(CreateSnippetRequest) {
  use data <- decode.field("data", data_decoder())
  decode.success(CreateSnippetRequest(data: data))
}

pub type UpdateSnippetRequest {
  UpdateSnippetRequest(slug: String, data: SnippetData)
}

pub fn update_decoder() -> decode.Decoder(UpdateSnippetRequest) {
  use slug <- decode.field("slug", decode.string)
  use data <- decode.field("data", data_decoder())
  decode.success(UpdateSnippetRequest(slug: slug, data: data))
}

pub type SnippetResponse {
  SnippetResponse(
    slug: String,
    user: user_dto.UserResponse,
    data: SnippetData,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub type ListSnippetsResponse {
  ListSnippetsResponse(page: pagination_model.CursorPage(SnippetResponse))
}

pub fn response_decoder() -> decode.Decoder(SnippetResponse) {
  use slug <- decode.field("slug", decode.string)
  use user <- decode.field("user", user_dto.user_decoder())
  use title <- decode.field("title", decode.string)
  use language <- decode.field("language", language.decoder())
  use visibility <- decode.field(
    "visibility",
    snippet_model.visibility_decoder(),
  )
  use stdin <- decode.field("stdin", decode.string)
  use run_instructions <- decode.field(
    "runInstructions",
    decode.optional(language.run_instructions_decoder()),
  )
  use files <- decode.field("files", decode.list(snippet_model.file_decoder()))
  use created_at <- decode.field("createdAt", timestamp_helpers.decoder())
  use updated_at <- decode.field("updatedAt", timestamp_helpers.decoder())

  decode.success(SnippetResponse(
    slug: slug,
    user: user,
    data: SnippetData(
      title: title,
      language: language,
      visibility: visibility,
      stdin: stdin,
      run_instructions: run_instructions,
      files: files,
    ),
    created_at: created_at,
    updated_at: updated_at,
  ))
}

pub fn list_response_decoder() -> decode.Decoder(ListSnippetsResponse) {
  pagination_model.page_decoder("snippets", response_decoder())
  |> decode.map(fn(page) { ListSnippetsResponse(page: page) })
}

pub fn from_snippet(snippet: snippet_model.HydratedSnippet) -> SnippetResponse {
  SnippetResponse(
    slug: snippet.identity.slug,
    user: user_dto.from_user(snippet.user),
    data: data_from_snippet(snippet.identity),
    created_at: snippet.identity.created_at,
    updated_at: snippet.identity.updated_at,
  )
}

pub fn encode_response(response: SnippetResponse) -> json.Json {
  json.object([
    #("slug", json.string(response.slug)),
    #("user", user_dto.encode(response.user)),
    #("userId", json.string(uuid.to_string(response.user.id))),
    #("title", json.string(response.data.title)),
    #("language", language.encode(response.data.language)),
    #("visibility", snippet_model.encode_visibility(response.data.visibility)),
    #("stdin", json.string(response.data.stdin)),
    #(
      "runInstructions",
      json.nullable(
        response.data.run_instructions,
        language.encode_run_instructions,
      ),
    ),
    #("files", json.array(response.data.files, snippet_model.encode_file)),
    #("createdAt", timestamp_helpers.encode(response.created_at)),
    #("updatedAt", timestamp_helpers.encode(response.updated_at)),
  ])
}

pub fn from_snippets(
  page page: pagination_model.CursorPage(snippet_model.HydratedSnippet),
) -> ListSnippetsResponse {
  ListSnippetsResponse(page: pagination_model.map_page(page, from_snippet))
}

pub fn encode_list_response(response: ListSnippetsResponse) -> json.Json {
  pagination_model.encode_page(response.page, "snippets", encode_response)
}

pub type SnippetData {
  SnippetData(
    title: String,
    language: language.Language,
    visibility: snippet_model.Visibility,
    stdin: String,
    run_instructions: option.Option(language.RunInstructions),
    files: List(snippet_model.File),
  )
}

pub fn encode_data(data: SnippetData) -> json.Json {
  json.object([
    #("title", json.string(data.title)),
    #("language", language.encode(data.language)),
    #("visibility", snippet_model.encode_visibility(data.visibility)),
    #("stdin", json.string(data.stdin)),
    #(
      "runInstructions",
      json.nullable(data.run_instructions, language.encode_run_instructions),
    ),
    #("files", json.array(data.files, snippet_model.encode_file)),
  ])
}

pub fn data_decoder() -> decode.Decoder(SnippetData) {
  use title <- decode.field("title", decode.string)
  use lang <- decode.field("language", language.decoder())
  use visibility <- decode.field(
    "visibility",
    snippet_model.visibility_decoder(),
  )
  use stdin <- decode.field("stdin", decode.string)
  use run_instructions <- decode.field(
    "runInstructions",
    decode.optional(language.run_instructions_decoder()),
  )
  use files <- decode.field("files", decode.list(snippet_model.file_decoder()))

  decode.success(SnippetData(
    title: title,
    language: lang,
    visibility: visibility,
    stdin: stdin,
    run_instructions: run_instructions,
    files: files,
  ))
}

fn data_from_snippet(snippet: snippet_model.Snippet) -> SnippetData {
  SnippetData(
    title: snippet.title,
    language: snippet.language,
    visibility: snippet.visibility,
    stdin: snippet.stdin,
    run_instructions: snippet.run_instructions,
    files: snippet.files,
  )
}
