import glot_backend/app_config/model/config.{type DynamicConfig}
import glot_backend/app_config/ports/listener.{type Listener}
import glot_backend/system/http/pool

pub fn new(pools: pool.Pools) -> Listener {
  listener.Listener(updated: fn(config) {
    pool.configure_all(pools, pool_config(config))
  })
}

pub fn pool_config(config: DynamicConfig) -> pool.Config {
  let config = config.http_pool
  pool.Config(
    docker_run_max_sessions: config.docker_run_max_sessions,
    cloudflare_email_max_sessions: config.cloudflare_email_max_sessions,
    keep_alive_timeout_ms: config.keep_alive_timeout_ms,
  )
}
