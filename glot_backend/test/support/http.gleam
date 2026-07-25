import gleam/erlang/process
import gleam/http
import gleam/http/request as http_request
import gleam/option
import gleam/regexp
import gleam/time/timestamp
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/ports/cache
import glot_backend/logging/ingestion/ports/sink.{type Sink}
import glot_backend/page
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/system/cache/cache_outcome
import glot_backend/system/effect/adapter/service_ports as service_ports_adapter
import glot_backend/system/effect/cache_ports
import glot_backend/system/effect/runtime.{type Runtime}
import glot_backend/system/file_system
import glot_backend/system/http/pool as http_pool
import glot_backend/system/lifecycle/request_tracker/ports/request_tracker.{
  type RequestTracker,
}
import glot_backend/system/lifecycle/server_mode/model as server_mode
import glot_backend/system/lifecycle/server_mode/worker as server_mode_worker
import glot_backend/system/request/context
import glot_core/availability_mode
import pog
import wisp/simulate
import youid/uuid

pub fn page_body(path: String) -> String {
  page_body_with_optional_theme(path, option.None)
}

pub fn page_body_with_theme(path: String, theme: String) -> String {
  page_body_with_optional_theme(path, option.Some(theme))
}

pub fn page_body_with_optional_theme(
  path: String,
  theme: option.Option(String),
) -> String {
  let assert Ok(_) = write_test_manifest()
  let availability =
    request_policy_config.AvailabilityConfig(
      mode: availability_mode.NormalMode,
      message: "",
      retry_after_seconds: option.None,
    )
  let request = case theme {
    option.Some(theme) ->
      simulate.request(http.Get, path)
      |> http_request.set_cookie("glot_theme", theme)
    option.None -> simulate.request(http.Get, path)
  }
  let response =
    page.handle_request(
      test_runtime(
        pog.named_connection(process.new_name("frontend_entry_http_db")),
        test_dynamic_config(availability),
      ),
      test_context(),
      no_op_log_sink(),
      request,
    )

  assert response.status == 200
  simulate.read_body(response)
}

pub fn no_op_log_sink() -> Sink {
  sink.Sink(
    write_api: fn(_) { Nil },
    write_page: fn(_) { Nil },
    write_pageview: fn(_) { Nil },
    drain: fn() { Nil },
  )
}

pub fn no_op_request_tracker() -> RequestTracker {
  request_tracker.RequestTracker(
    started: fn() { Nil },
    finished: fn() { Nil },
    count: fn() { 0 },
  )
}

pub fn test_runtime(
  db: pog.Connection,
  config: dynamic_config.DynamicConfig,
) -> Runtime {
  runtime.new(service_ports_adapter.new(
    db,
    cache_ports.CachePorts(
      app_config_cache: option.Some(
        cache.Cache(
          lookup: fn() { #(Ok(config), cache_outcome.CacheHit) },
          refresh: fn() { Ok(config) },
        ),
      ),
      language_version_cache: option.None,
    ),
    http_pool.new(),
  ))
}

pub fn start_server_mode(
  mode: server_mode.Mode,
) -> process.Subject(server_mode_worker.Message) {
  let name = process.new_name("csrf_http_server_mode")
  let assert Ok(_) = server_mode_worker.start_in(name, mode)
  process.named_subject(name)
}

pub fn test_dynamic_config(
  availability: request_policy_config.AvailabilityConfig,
) -> dynamic_config.DynamicConfig {
  dynamic_config.DynamicConfig(
    ..dynamic_config.empty(),
    availability: availability,
  )
}

pub fn test_context() -> context.Context {
  let assert Ok(is_email) = regexp.from_string(".*")

  context.Context(
    config: context.Config(
      app_env: context.Dev,
      encryption_key: "test",
      listening_address: "localhost",
      listening_port: 3000,
      static_base_path: test_static_base_path(),
      postgres: context.PostgresConfig(
        host: "localhost",
        port: 5432,
        db: "test",
        user: "test",
        pass: "test",
        pool_size: 1,
      ),
    ),
    regexes: context.Regexes(is_email: is_email),
    request_id: uuid.nil,
    started_at: 0,
    deadline_at_monotonic_ns: option.None,
    timestamp: timestamp.system_time(),
    client_info: context.empty_client_info(),
  )
}

pub fn test_static_base_path() -> String {
  "/tmp/glot_backend_availability_http_static"
}

pub fn write_test_manifest() -> Result(Nil, String) {
  file_system.write_file(
    test_static_base_path() <> "/manifest.json",
    "{\"js/public.ts\":{\"file\":\"assets/test-frontend.js\",\"imports\":[\"_shared.js\"]},\"js/admin.ts\":{\"file\":\"assets/test-admin.js\",\"css\":[\"assets/test-admin.css\"],\"imports\":[\"_shared.js\"]},\"js/custom_elements/glot-codemirror.ts\":{\"file\":\"assets/test-codemirror.js\",\"imports\":[\"_shared.js\",\"_codemirror-shared.js\"]},\"js/styles.ts\":{\"file\":\"assets/empty.js\",\"css\":[\"assets/test-styles.css\"]},\"assets/home-banner.jpg\":{\"file\":\"assets/test-home-banner.jpg\"},\"_shared.js\":{\"file\":\"assets/test-shared.js\"},\"_codemirror-shared.js\":{\"file\":\"assets/test-codemirror-shared.js\"}}",
  )
}
