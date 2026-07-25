import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/erlang/charlist.{type Charlist}
import gleam/http.{type Method}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/list
import gleam/result
import gleam/uri
import glot_backend/system/http/pool.{type Pool}

type ErlHttpOption {
  Autoredirect(Bool)
  Timeout(Int)
}

type BodyFormat {
  Binary
}

type ErlOption {
  BodyFormat(BodyFormat)
  SocketOpts(List(SocketOpt))
}

type SocketOpt {
  Ipfamily(Inet6fb4)
}

type Inet6fb4 {
  Inet6fb4
}

@external(erlang, "http_pool_ffi", "request")
fn erl_request(
  method: Method,
  request: #(Charlist, List(#(Charlist, Charlist)), Charlist, BitArray),
  http_options: List(ErlHttpOption),
  options: List(ErlOption),
  profile: Pool,
) -> Result(
  #(#(Charlist, Int, Charlist), List(#(Charlist, Charlist)), BitArray),
  Dynamic,
)

@external(erlang, "gleam_httpc_ffi", "normalise_error")
fn normalise_error(error: Dynamic) -> httpc.HttpError

pub fn dispatch(
  pool: Pool,
  timeout_ms: Int,
  req: Request(String),
) -> Result(Response(String), httpc.HttpError) {
  let erl_url =
    req
    |> request.to_uri
    |> uri.to_string
    |> charlist.from_string
  let erl_headers = prepare_headers(req.headers)
  let content_type =
    req
    |> request.get_header("content-type")
    |> result.unwrap("application/octet-stream")
    |> charlist.from_string
  let prepared_request = #(
    erl_url,
    erl_headers,
    content_type,
    bit_array.from_string(req.body),
  )
  let http_options = [Autoredirect(False), Timeout(timeout_ms)]
  let options = [BodyFormat(Binary), SocketOpts([Ipfamily(Inet6fb4)])]

  use response <- result.try(
    erl_request(req.method, prepared_request, http_options, options, pool)
    |> result.map_error(normalise_error),
  )

  let #(#(_version, status, _status), headers, body) = response
  use body <- result.try(
    bit_array.to_string(body)
    |> result.map_error(fn(_) { httpc.InvalidUtf8Response }),
  )

  Ok(Response(status, list.map(headers, string_header), body))
}

fn prepare_headers(
  headers: List(#(String, String)),
) -> List(#(Charlist, Charlist)) {
  prepare_headers_loop(headers, [], False)
}

fn prepare_headers_loop(
  remaining: List(#(String, String)),
  prepared: List(#(Charlist, Charlist)),
  user_agent_set: Bool,
) -> List(#(Charlist, Charlist)) {
  case remaining {
    [] if user_agent_set -> prepared
    [] -> [default_user_agent(), ..prepared]
    [#(key, value), ..remaining] ->
      prepare_headers_loop(
        remaining,
        [#(charlist.from_string(key), charlist.from_string(value)), ..prepared],
        user_agent_set || key == "user-agent",
      )
  }
}

@external(erlang, "gleam_httpc_ffi", "default_user_agent")
fn default_user_agent() -> #(Charlist, Charlist)

fn string_header(header: #(Charlist, Charlist)) -> #(String, String) {
  let #(key, value) = header
  #(charlist.to_string(key), charlist.to_string(value))
}
