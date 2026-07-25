import envoy
import gleam/dict
import gleam/erlang/process
import gleam/http/request
import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import gleam/time/timestamp
import glot_backend/app_config/adapter/cache/worker as app_config_cache_adapter
import glot_backend/app_config/adapter/http_pool/listener as http_pool_listener
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/job/adapter/tracker/worker as job_tracker_adapter
import glot_backend/logging/ingestion/adapter/worker/sink as logging_worker_sink
import glot_backend/run_code/adapter/cache/worker as language_version_cache_adapter
import glot_backend/system/application/router
import glot_backend/system/application/shutdown
import glot_backend/system/application/supervisor
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/adapter/service_ports as service_ports_adapter
import glot_backend/system/effect/cache_ports
import glot_backend/system/effect/runtime
import glot_backend/system/http/pool as http_pool
import glot_backend/system/http/response as response_helpers
import glot_backend/system/lifecycle/request_tracker/adapter/worker as request_tracker_adapter
import glot_backend/system/lifecycle/server_mode/adapter/worker as server_mode_adapter
import glot_backend/system/request/context
import glot_backend/system/runtime/erlang
import glot_core/email/email_address_model
import mist
import pog
import signal_handler
import wisp
import wisp/wisp_mist
import youid/uuid

pub fn start() {
  let signal_name = process.new_name("graceful_gleam_sigterm")
  let assert Ok(Nil) = process.register(process.self(), signal_name)
  let signal_subject = process.named_subject(signal_name)

  wisp.configure_logger()
  signal_handler.install(signal_name)

  let assert Ok(priv_directory) = wisp.priv_directory("glot_backend")
  let static_directory = priv_directory <> "/static"
  let migrations_directory = priv_directory <> "/db/migrations"

  let default_env =
    dict.from_list([
      #("LISTENING_ADDRESS", "localhost"),
      #("LISTENING_PORT", "3000"),
      #("STATIC_BASE_PATH", static_directory),
    ])

  let env_values = dict.merge(default_env, envoy.all())

  let assert Ok(config) = context.config_from_dict(env_values)
  let http_pools = http_pool.new()
  let assert Ok(Nil) =
    http_pool.start_all(
      http_pools,
      http_pool_listener.pool_config(dynamic_config.empty()),
    )
  let seeds_directory =
    priv_directory <> "/db/seeds/" <> context.app_env_to_string(config.app_env)
  let postgres_pool_name = process.new_name("postgres_pool")
  let postgres = postgres_config(config, postgres_pool_name)
  let db = pog.named_connection(postgres_pool_name)
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  let regexes = context.Regexes(is_email)
  let log_worker_name = process.new_name("log_worker")
  let log_sink =
    process.named_subject(log_worker_name)
    |> logging_worker_sink.new
  let job_tracker_name = process.new_name("job_tracker")
  let job_tracker_subject = process.named_subject(job_tracker_name)
  let job_tracker = job_tracker_adapter.new(job_tracker_subject)
  let request_tracker_name = process.new_name("request_tracker")
  let request_tracker_subject = process.named_subject(request_tracker_name)
  let request_tracker = request_tracker_adapter.new(request_tracker_subject)
  let server_mode_name = process.new_name("server_mode")
  let server_mode_subject = process.named_subject(server_mode_name)
  let server_mode = server_mode_adapter.new(server_mode_subject)
  let language_version_cache_worker_name =
    process.new_name("language_version_cache_worker")
  let language_version_cache_subject =
    process.named_subject(language_version_cache_worker_name)
  let app_config_cache_worker_name = process.new_name("app_config_cache_worker")
  let app_config_cache_subject =
    process.named_subject(app_config_cache_worker_name)
  let app_config_cache = app_config_cache_adapter.new(app_config_cache_subject)
  let language_version_cache =
    language_version_cache_adapter.new(language_version_cache_subject)
  let effect_runtime =
    runtime.new(service_ports_adapter.new(
      db,
      cache_ports.new(app_config_cache, language_version_cache),
      http_pools,
    ))
  let mist_handler = fn(conn: request.Request(mist.Connection)) {
    wisp_mist.handler(
      fn(req: request.Request(wisp.Connection)) {
        let ctx =
          context.Context(
            config: config,
            request_id: uuid.v7(),
            started_at: erlang.perf_counter_ns(),
            deadline_at_monotonic_ns: option.None,
            timestamp: timestamp.system_time(),
            regexes: regexes,
            client_info: get_client_info(req, conn.body),
          )

        router.handle_request(
          effect_runtime,
          ctx,
          log_sink,
          request_tracker,
          server_mode,
          req,
        )
        |> response_helpers.with_request_id(ctx.request_id)
      },
      config.encryption_key,
    )(conn)
  }

  let mist_builder =
    mist.new(mist_handler)
    |> mist.bind(config.listening_address)
    |> mist.port(config.listening_port)

  let assert Ok(_) =
    supervisor.start(supervisor.Config(
      startup: supervisor.StartupConfig(
        postgres: postgres,
        db: db,
        migrations_directory: migrations_directory,
        seeds_directory: seeds_directory,
        app: config,
        regexes: regexes,
      ),
      dependencies: supervisor.Dependencies(
        effect_runtime: effect_runtime,
        app_config_cache: app_config_cache,
        job_tracker: job_tracker,
        server_mode: server_mode,
        http_pools: http_pools,
      ),
      worker_names: supervisor.WorkerNames(
        log_worker_name: log_worker_name,
        job_tracker_name: job_tracker_name,
        request_tracker_name: request_tracker_name,
        server_mode_name: server_mode_name,
        app_config_cache_worker_name: app_config_cache_worker_name,
        language_version_cache_worker_name: language_version_cache_worker_name,
      ),
      mist_builder: mist_builder,
    ))

  shutdown.wait_for_signal(
    signal_subject,
    log_sink,
    server_mode,
    request_tracker,
    job_tracker,
  )
}

fn get_client_info(
  req: wisp.Request,
  conn: mist.Connection,
) -> context.ClientInfo {
  context.client_info(
    session_token: wisp.get_cookie(req, "session", wisp.Signed)
      |> option.from_result(),
    ip: get_header(req, "x-forwarded-for")
      |> option.lazy_or(fn() { get_client_ip(conn) }),
    user_agent: get_header(req, "user-agent"),
    referrer: get_header(req, "referer"),
  )
}

fn get_header(req: wisp.Request, name: String) -> option.Option(String) {
  list.find_map(req.headers, fn(header) {
    let #(header_name, header_value) = header
    case string.lowercase(header_name) == string.lowercase(name) {
      True -> Ok(header_value)
      False -> Error(Nil)
    }
  })
  |> option.from_result()
}

fn get_client_ip(conn: mist.Connection) -> option.Option(String) {
  case mist.get_connection_info(conn) {
    Ok(client_info) ->
      option.Some(mist.ip_address_to_string(client_info.ip_address))
    Error(_) -> option.None
  }
}

fn postgres_config(
  config: context.Config,
  pool_name: process.Name(pog.Message),
) -> pog.Config {
  pog.default_config(pool_name)
  |> pog.host(config.postgres.host)
  |> pog.port(config.postgres.port)
  |> pog.database(config.postgres.db)
  |> pog.user(config.postgres.user)
  |> pog.password(option.Some(config.postgres.pass))
  |> pog.pool_size(config.postgres.pool_size)
  |> pog.connection_parameter(
    "statement_timeout",
    db_helpers.statement_timeout_parameter(),
  )
}
