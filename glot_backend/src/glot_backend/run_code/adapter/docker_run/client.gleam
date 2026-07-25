import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string
import glot_backend/run_code/model/config as run_code_config
import glot_backend/run_code/ports/runner
import glot_backend/system/effect/error/run_request_error
import glot_backend/system/http/client as http_client
import glot_backend/system/http/pool.{type Pool}
import glot_core/run
import wisp

pub fn new(pool: Pool) -> runner.Runner {
  runner.Runner(run: fn(config, request, timeout_ms) {
    run_code(pool, config, request, timeout_ms)
  })
}

pub fn run_code(
  pool: Pool,
  cfg: run_code_config.DockerRunConfig,
  request: run.RunRequest,
  timeout_ms: Int,
) -> Result(run.RunResult, run_request_error.RunRequestError) {
  http_client.post_json(
    using: pool,
    url: cfg.base_url <> "/run",
    body: run.encode_run_request(request),
    headers: dict.from_list([#("X-Access-Token", cfg.access_token)]),
    timeout_ms: timeout_ms,
    decoder: run.run_result_decoder(),
  )
  |> result.map_error(map_run_http_error)
}

fn map_run_http_error(
  err: http_client.HttpError,
) -> run_request_error.RunRequestError {
  case err {
    http_client.BadStatus(status: _, body: body) ->
      case json.parse(body, run_error_message_decoder()) {
        Ok(message) -> run_request_error.ClientRunRequestError(message)
        Error(_) -> {
          wisp.log_error(
            "Failed to decode docker run error: " <> string.inspect(err),
          )
          run_request_error.ServerRunRequestError
        }
      }
    _ -> {
      wisp.log_error("Docker run request failed: " <> string.inspect(err))
      run_request_error.ServerRunRequestError
    }
  }
}

fn run_error_message_decoder() -> decode.Decoder(String) {
  use message <- decode.field("message", decode.string)
  decode.success(message)
}
