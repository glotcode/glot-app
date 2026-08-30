import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import glot_core/language
import glot_core/snippet/snippet_model
import glot_core/validation_error

pub type RunRequest {
  RunRequest(image: String, payload: RunRequestPayload)
}

pub type GetLanguageVersionRequest {
  GetLanguageVersionRequest(language: language.Language)
}

pub type RunRequestPayload {
  RunRequestPayload(
    run_instructions: language.RunInstructions,
    files: List(snippet_model.File),
    stdin: Option(String),
  )
}

pub type SuccessfulRun {
  SuccessfulRun(duration: Int, stdout: String, stderr: String, error: String)
}

pub type FailedRun {
  FailedRun(message: String)
}

pub type RunResult =
  Result(SuccessfulRun, FailedRun)

pub fn snippet_request(
  snippet_language: language.Language,
  run_instructions_override: Option(language.RunInstructions),
  files: List(snippet_model.File),
  stdin: Option(String),
) -> RunRequest {
  RunRequest(
    image: language.container_image(snippet_language),
    payload: RunRequestPayload(
      run_instructions: effective_run_instructions(
        snippet_language,
        run_instructions_override,
        files,
      ),
      files: files,
      stdin: stdin,
    ),
  )
}

pub fn effective_run_instructions(
  snippet_language: language.Language,
  run_instructions_override: Option(language.RunInstructions),
  files: List(snippet_model.File),
) -> language.RunInstructions {
  case run_instructions_override {
    option.Some(run_instructions) -> run_instructions
    option.None -> default_run_instructions(snippet_language, files)
  }
}

pub fn default_run_instructions(
  snippet_language: language.Language,
  files: List(snippet_model.File),
) -> language.RunInstructions {
  let default_name = language.default_filename(snippet_language)
  let names = list.map(files, fn(file) { file.name })
  let main_file = case list.find(names, fn(name) { name == default_name }) {
    Ok(name) -> name
    Error(_) -> list.first(names) |> result.unwrap("")
  }
  let other_files = remove_first(names, main_file)
  language.run_instructions(snippet_language, main_file, other_files)
}

fn remove_first(values: List(a), target: a) -> List(a) {
  case values {
    [] -> []
    [value, ..rest] if value == target -> rest
    [value, ..rest] -> [value, ..remove_first(rest, target)]
  }
}

pub fn is_empty(r: SuccessfulRun) -> Bool {
  r.stdout == "" && r.stderr == "" && r.error == ""
}

pub fn encode_run_request(req: RunRequest) -> json.Json {
  json.object([
    #("image", json.string(req.image)),
    #("payload", encode_run_request_payload(req.payload)),
  ])
}

pub fn encode_run_request_payload(payload: RunRequestPayload) -> json.Json {
  json.object([
    #(
      "runInstructions",
      language.encode_run_instructions(payload.run_instructions),
    ),
    #("files", json.array(payload.files, snippet_model.encode_file)),
    #("stdin", case payload.stdin {
      option.Some(s) -> json.string(s)
      option.None -> json.null()
    }),
  ])
}

pub fn run_request_decoder() -> decode.Decoder(RunRequest) {
  use image <- decode.field("image", decode.string)
  use payload <- decode.field("payload", run_request_payload_decoder())
  decode.success(RunRequest(image:, payload:))
}

pub fn encode_get_language_version_request(
  request: GetLanguageVersionRequest,
) -> json.Json {
  json.object([
    #("language", language.encode(request.language)),
  ])
}

pub fn get_language_version_request_decoder() -> decode.Decoder(
  GetLanguageVersionRequest,
) {
  use language <- decode.field("language", language.decoder())
  decode.success(GetLanguageVersionRequest(language:))
}

pub fn run_request_payload_decoder() -> decode.Decoder(RunRequestPayload) {
  use run_instructions <- decode.field(
    "runInstructions",
    language.run_instructions_decoder(),
  )
  use files <- decode.field("files", decode.list(snippet_model.file_decoder()))
  use stdin <- decode.field("stdin", decode.optional(decode.string))

  decode.success(RunRequestPayload(
    run_instructions: run_instructions,
    files: files,
    stdin: stdin,
  ))
}

pub fn validate_request(
  request: RunRequest,
) -> Result(language.Language, validation_error.ValidationError) {
  use request_language <- result.try(validate_image(request.image))
  use _ <- result.try(validate_payload(request.payload))
  Ok(request_language)
}

fn validate_image(
  image: String,
) -> Result(language.Language, validation_error.ValidationError) {
  case language.from_container_image(image) {
    option.Some(language) -> Ok(language)
    option.None -> Error(validation_error.UnknownRunLanguage(image))
  }
}

fn validate_payload(
  payload: RunRequestPayload,
) -> Result(Nil, validation_error.ValidationError) {
  snippet_model.validate_execution_fields(
    case payload.stdin {
      option.Some(stdin) -> stdin
      option.None -> ""
    },
    option.Some(payload.run_instructions),
    payload.files,
  )
}

pub fn successful_run_decoder() -> decode.Decoder(SuccessfulRun) {
  use duration <- decode.field("duration", decode.int)
  use stdout <- decode.field("stdout", decode.string)
  use stderr <- decode.field("stderr", decode.string)
  use error <- decode.field("error", decode.string)
  decode.success(SuccessfulRun(duration:, stdout:, stderr:, error:))
}

pub fn failed_run_decoder() -> decode.Decoder(FailedRun) {
  use message <- decode.field("message", decode.string)
  decode.success(FailedRun(message:))
}

pub fn run_result_decoder() -> decode.Decoder(RunResult) {
  decode.one_of(decode.map(successful_run_decoder(), Ok), or: [
    decode.map(failed_run_decoder(), Error),
  ])
}

pub fn encode_run_result(result: RunResult) -> json.Json {
  case result {
    Ok(success) ->
      json.object([
        #("duration", json.int(success.duration)),
        #("stdout", json.string(success.stdout)),
        #("stderr", json.string(success.stderr)),
        #("error", json.string(success.error)),
      ])
    Error(failure) ->
      json.object([
        #("message", json.string(failure.message)),
      ])
  }
}
