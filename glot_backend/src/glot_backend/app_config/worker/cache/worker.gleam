import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import gleam/otp/supervision
import gleam/result
import gleam/string
import glot_backend/app_config/decoder/config as config_decoder
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/ports/listener.{type Listener}
import glot_backend/app_config/ports/store.{type Store}
import glot_backend/app_config/worker/cache/core
import glot_backend/system/cache/worker/support as cache_worker_support
import glot_backend/system/effect/error/db_error
import glot_backend/system/lifecycle/server_mode/model
import glot_backend/system/lifecycle/server_mode/ports/controller.{
  type Controller,
}
import glot_backend/system/runtime/erlang
import wisp

const call_timeout_ms = 5000

pub type Message {
  GetConfig(
    reply: process.Subject(
      cache_worker_support.Lookup(
        Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
      ),
    ),
  )
  Refresh(
    reply: process.Subject(
      cache_worker_support.Lookup(
        Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
      ),
    ),
  )
  Tick
  RefreshCompleted(
    fetched_at_ns: Int,
    result: Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
  )
}

pub type Deps {
  Deps(
    fetch_config: fn() ->
      Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
    now_ns: fn() -> Int,
    config_updated: fn(dynamic_config.DynamicConfig) -> Result(Nil, String),
  )
}

type State {
  State(
    subject: process.Subject(Message),
    server_mode: Controller,
    deps: Deps,
    core: core.State,
  )
}

pub fn start(
  name: process.Name(Message),
  store: Store,
  listener: Listener,
  server_mode: Controller,
) {
  start_with_deps(
    name,
    server_mode,
    Deps(
      fetch_config: fn() {
        store.list_entries()
        |> result.try(fn(entries) {
          config_decoder.from_entries(entries)
          |> result.map_error(db_error.DbQueryError)
        })
      },
      now_ns: erlang.perf_counter_ns,
      config_updated: listener.updated,
    ),
  )
}

pub fn start_with_deps(
  name: process.Name(Message),
  server_mode: Controller,
  deps: Deps,
) {
  actor.new_with_initialiser(1000, fn(subject) {
    let initial_state =
      State(
        subject: subject,
        server_mode: server_mode,
        deps: deps,
        core: core.new(),
      )
    let _ = process.send(subject, Tick)
    let initialised = actor.initialised(initial_state)
    Ok(actor.returning(initialised, Nil))
  })
  |> actor.named(name)
  |> actor.on_message(handle_message)
  |> actor.start
}

pub fn supervised(
  name: process.Name(Message),
  store: Store,
  listener: Listener,
  server_mode: Controller,
) {
  supervision.worker(fn() { start(name, store, listener, server_mode) })
}

pub fn get_config(
  subject: process.Subject(Message),
) -> Result(dynamic_config.DynamicConfig, db_error.DbQueryError) {
  let cache_worker_support.Lookup(value:, ..) = lookup_config(subject)
  value
}

pub fn lookup_config(
  subject: process.Subject(Message),
) -> cache_worker_support.Lookup(
  Result(dynamic_config.DynamicConfig, db_error.DbQueryError),
) {
  process.call(subject, call_timeout_ms, GetConfig)
}

pub fn refresh(
  subject: process.Subject(Message),
) -> Result(dynamic_config.DynamicConfig, db_error.DbQueryError) {
  let cache_worker_support.Lookup(value:, ..) =
    process.call(subject, call_timeout_ms, Refresh)
  value
}

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    GetConfig(reply) -> {
      let now_ns = state.deps.now_ns()
      let #(next_core, commands) =
        core.on_get(state.core, reply, now_ns, can_fetch(state))
      actor.continue(run_commands(State(..state, core: next_core), commands))
    }
    Refresh(reply) -> {
      let #(next_core, commands) =
        core.on_refresh_requested(state.core, reply, can_fetch(state))
      actor.continue(run_commands(State(..state, core: next_core), commands))
    }
    Tick -> {
      let #(next_core, commands) =
        core.on_tick(state.core, state.deps.now_ns(), can_fetch(state))
      actor.continue(run_commands(State(..state, core: next_core), commands))
    }
    RefreshCompleted(fetched_at_ns, result) -> {
      let #(next_core, commands) =
        core.on_fetch_completed(state.core, fetched_at_ns, result)
      actor.continue(run_commands(State(..state, core: next_core), commands))
    }
  }
}

fn run_commands(state: State, commands: List(core.Command)) -> State {
  list.fold(commands, state, fn(state: State, command) {
    case command {
      core.ScheduleTick(delay_ms) -> {
        let _ = process.send_after(state.subject, delay_ms, Tick)
        state
      }
      core.StartFetch -> {
        let subject = state.subject
        let deps = state.deps
        let _ =
          process.spawn_unlinked(fn() {
            let result = deps.fetch_config()
            let fetched_at_ns = deps.now_ns()
            process.send(
              subject,
              RefreshCompleted(fetched_at_ns:, result: result),
            )
          })
        state
      }
      core.ConfigUpdated(config) -> {
        case state.deps.config_updated(config) {
          Ok(Nil) -> Nil
          Error(message) ->
            wisp.log_warning("Failed to apply dynamic app config: " <> message)
        }
        state
      }
      core.Reply(reply, result) -> {
        process.send(reply, result)
        state
      }
      core.LogRefreshError(err) -> {
        wisp.log_warning(
          "Failed to refresh app config cache: " <> string.inspect(err),
        )
        state
      }
    }
  })
}

fn can_fetch(state: State) -> Bool {
  state.server_mode.current() == model.Running
}
