import gleam/erlang/process
import gleam/otp/static_supervisor
import glot_backend/app_config/adapter/http_pool/listener as http_pool_listener
import glot_backend/app_config/adapter/postgres/store as app_config_postgres_store
import glot_backend/app_config/ports/cache.{type Cache}
import glot_backend/app_config/worker/cache/worker as app_config_cache_worker
import glot_backend/job/adapter/executor as job_executor_adapter
import glot_backend/job/adapter/postgres/log_store as job_postgres_log_store
import glot_backend/job/ports/tracker.{type Tracker}
import glot_backend/job/worker/executor/worker as job_worker
import glot_backend/job/worker/tracker/worker as job_tracker_worker
import glot_backend/logging/ingestion/adapter/app_config/config_provider as logging_config_provider
import glot_backend/logging/ingestion/adapter/batcher as logging_batcher_adapter
import glot_backend/logging/ingestion/adapter/postgres/batch_store as logging_postgres_batch_store
import glot_backend/logging/ingestion/worker/batcher/worker as log_worker
import glot_backend/run_code/adapter/docker_run/client as docker_run_client
import glot_backend/run_code/worker/language_version_cache/worker as language_version_cache_worker
import glot_backend/system/database as db_helpers
import glot_backend/system/effect/runtime.{type Runtime}
import glot_backend/system/http/pool.{type Pools}
import glot_backend/system/lifecycle/database_health/adapter/postgres/checker as database_health_postgres_checker
import glot_backend/system/lifecycle/database_health/worker as database_health_worker
import glot_backend/system/lifecycle/request_tracker/worker as request_tracker_worker
import glot_backend/system/lifecycle/server_mode/model
import glot_backend/system/lifecycle/server_mode/ports/controller.{
  type Controller,
}
import glot_backend/system/lifecycle/server_mode/worker as server_mode_worker
import glot_backend/system/lifecycle/startup/adapter/postgres/runner as startup_postgres_runner
import glot_backend/system/lifecycle/startup/worker as startup_worker
import glot_backend/system/request/context
import glot_core/job/job_model
import mist
import pog

pub type StartupConfig {
  StartupConfig(
    postgres: pog.Config,
    db: pog.Connection,
    migrations_directory: String,
    seeds_directory: String,
    app: context.Config,
    regexes: context.Regexes,
  )
}

pub type Dependencies {
  Dependencies(
    effect_runtime: Runtime,
    app_config_cache: Cache,
    job_tracker: Tracker,
    server_mode: Controller,
    http_pools: Pools,
  )
}

pub type WorkerNames {
  WorkerNames(
    log_worker_name: process.Name(log_worker.Message),
    job_tracker_name: process.Name(job_tracker_worker.Message),
    request_tracker_name: process.Name(request_tracker_worker.Message),
    server_mode_name: process.Name(server_mode_worker.Message),
    app_config_cache_worker_name: process.Name(app_config_cache_worker.Message),
    language_version_cache_worker_name: process.Name(
      language_version_cache_worker.Message,
    ),
    default_job_executor_name: process.Name(job_worker.Message),
    spam_classifier_job_executor_name: process.Name(job_worker.Message),
  )
}

pub type Config {
  Config(
    startup: StartupConfig,
    dependencies: Dependencies,
    worker_names: WorkerNames,
    mist_builder: mist.Builder(mist.Connection, mist.ResponseData),
  )
}

pub fn start(config: Config) {
  let startup = config.startup
  let dependencies = config.dependencies
  let worker_names = config.worker_names
  let job_log_store = job_postgres_log_store.new(db_helpers.new(startup.db))
  let default_job_executor_deps =
    job_executor_adapter.new(
      dependencies.effect_runtime,
      job_log_store,
      job_model.DefaultQueue,
    )
  let spam_classifier_job_executor_deps =
    job_executor_adapter.new(
      dependencies.effect_runtime,
      job_log_store,
      job_model.SpamClassifierQueue,
    )
  let logging_deps =
    logging_batcher_adapter.new(
      logging_config_provider.new(dependencies.app_config_cache),
      logging_postgres_batch_store.new(startup.db),
    )

  static_supervisor.new(static_supervisor.OneForAll)
  |> static_supervisor.add(pog.supervised(startup.postgres))
  |> static_supervisor.add(server_mode_worker.supervised_in(
    worker_names.server_mode_name,
    model.Maintenance,
  ))
  |> static_supervisor.add(database_health_worker.supervised(
    database_health_postgres_checker.new(startup.db),
    dependencies.server_mode,
  ))
  |> static_supervisor.add(startup_worker.supervised(
    startup_postgres_runner.new(
      startup.db,
      startup.migrations_directory,
      startup.seeds_directory,
    ),
    dependencies.server_mode,
  ))
  |> static_supervisor.add(app_config_cache_worker.supervised(
    worker_names.app_config_cache_worker_name,
    app_config_postgres_store.new(db_helpers.new(startup.db)),
    http_pool_listener.new(dependencies.http_pools),
    dependencies.server_mode,
  ))
  |> static_supervisor.add(log_worker.supervised(
    worker_names.log_worker_name,
    logging_deps,
  ))
  |> static_supervisor.add(language_version_cache_worker.supervised(
    worker_names.language_version_cache_worker_name,
    dependencies.app_config_cache,
    docker_run_client.new(dependencies.http_pools.docker_run),
    dependencies.server_mode,
  ))
  |> static_supervisor.add(request_tracker_worker.supervised(
    worker_names.request_tracker_name,
  ))
  |> static_supervisor.add(job_tracker_worker.supervised(
    worker_names.job_tracker_name,
  ))
  |> static_supervisor.add(job_worker.supervised_named(
    worker_names.default_job_executor_name,
    startup.app,
    startup.regexes,
    dependencies.server_mode,
    dependencies.job_tracker,
    default_job_executor_deps,
  ))
  |> static_supervisor.add(job_worker.supervised_named(
    worker_names.spam_classifier_job_executor_name,
    startup.app,
    startup.regexes,
    dependencies.server_mode,
    dependencies.job_tracker,
    spam_classifier_job_executor_deps,
  ))
  |> static_supervisor.add(mist.supervised(config.mist_builder))
  |> static_supervisor.start
}
