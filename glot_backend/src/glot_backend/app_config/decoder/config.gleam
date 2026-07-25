import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import glot_backend/app_config/decoder/auth as auth_decoder
import glot_backend/app_config/decoder/email as email_decoder
import glot_backend/app_config/decoder/logging as logging_decoder
import glot_backend/app_config/decoder/request_policy as request_policy_decoder
import glot_backend/app_config/decoder/run_code as run_code_decoder
import glot_backend/app_config/decoder/system as system_decoder
import glot_backend/app_config/model/config.{type DynamicConfig}
import glot_backend/app_config/model/defaults
import glot_backend/app_config/model/entry.{type AppConfigEntry}

pub fn from_entries(
  entries: List(AppConfigEntry),
) -> Result(DynamicConfig, String) {
  list.fold(entries, Ok(empty()), fn(acc, entry) {
    use config <- result.try(acc)
    apply_entry(config, entry)
  })
}

fn empty() -> DynamicConfig {
  config.DynamicConfig(
    debug: defaults.debug(),
    http_pool: defaults.http_pool(),
    availability: defaults.availability(),
    auth: defaults.auth(),
    passkey: defaults.passkey(),
    cleanup: defaults.cleanup(),
    log_worker: defaults.log_worker(),
    language_version_cache_worker: defaults.language_version_cache_worker(),
    docker_run: option.None,
    cloudflare: option.None,
    email: option.None,
    rate_limit_policies: dict.new(),
  )
}

fn apply_entry(
  config: DynamicConfig,
  entry: AppConfigEntry,
) -> Result(DynamicConfig, String) {
  case entry.namespace {
    "debug" -> {
      use debug <- result.try(system_decoder.debug(config.debug, entry))
      Ok(config.DynamicConfig(..config, debug: debug))
    }
    "http_pool" -> {
      use http_pool <- result.try(system_decoder.http_pool(
        config.http_pool,
        entry,
      ))
      Ok(config.DynamicConfig(..config, http_pool: http_pool))
    }
    "availability" -> {
      use availability <- result.try(request_policy_decoder.availability(
        config.availability,
        entry,
      ))
      Ok(config.DynamicConfig(..config, availability: availability))
    }
    "auth" -> {
      use auth <- result.try(auth_decoder.auth(config.auth, entry))
      Ok(config.DynamicConfig(..config, auth: auth))
    }
    "passkey" -> {
      use passkey <- result.try(auth_decoder.passkey(config.passkey, entry))
      Ok(config.DynamicConfig(..config, passkey: passkey))
    }
    "cleanup" -> {
      use cleanup <- result.try(system_decoder.cleanup(config.cleanup, entry))
      Ok(config.DynamicConfig(..config, cleanup: cleanup))
    }
    "log_worker" -> {
      use log_worker <- result.try(logging_decoder.log_worker(
        config.log_worker,
        entry,
      ))
      Ok(config.DynamicConfig(..config, log_worker: log_worker))
    }
    "language_version_cache_worker" -> {
      use worker_config <- result.try(
        run_code_decoder.language_version_cache_worker(
          config.language_version_cache_worker,
          entry,
        ),
      )
      Ok(
        config.DynamicConfig(
          ..config,
          language_version_cache_worker: worker_config,
        ),
      )
    }
    "docker_run" -> {
      use docker_run <- result.try(run_code_decoder.docker_run(
        config.docker_run,
        defaults.docker_run(),
        entry,
      ))
      Ok(config.DynamicConfig(..config, docker_run: docker_run))
    }
    "cloudflare" -> {
      use cloudflare <- result.try(email_decoder.cloudflare(
        config.cloudflare,
        entry,
      ))
      Ok(config.DynamicConfig(..config, cloudflare: cloudflare))
    }
    "email" -> {
      use email <- result.try(email_decoder.email(
        config.email,
        defaults.email(),
        entry,
      ))
      Ok(config.DynamicConfig(..config, email: email))
    }
    "rate_limit" -> apply_rate_limit_entry(config, entry)
    _ -> Ok(config)
  }
}

fn apply_rate_limit_entry(
  config: DynamicConfig,
  entry: AppConfigEntry,
) -> Result(DynamicConfig, String) {
  use decoded <- result.try(request_policy_decoder.rate_limit(entry))
  case decoded {
    option.Some(#(action, policy)) ->
      Ok(
        config.DynamicConfig(
          ..config,
          rate_limit_policies: dict.insert(
            config.rate_limit_policies,
            action,
            policy,
          ),
        ),
      )
    option.None -> Ok(config)
  }
}
