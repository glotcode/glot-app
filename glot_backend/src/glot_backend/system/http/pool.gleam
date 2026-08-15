import gleam/result

pub opaque type Pool {
  Pool(PoolName)
}

type PoolName {
  DockerRun
  CloudflareEmail
  SpamClassifier
}

pub type Pools {
  Pools(docker_run: Pool, cloudflare_email: Pool, spam_classifier: Pool)
}

pub type Config {
  Config(
    docker_run_max_sessions: Int,
    cloudflare_email_max_sessions: Int,
    keep_alive_timeout_ms: Int,
  )
}

@external(erlang, "http_pool_ffi", "start")
fn start(
  pool: Pool,
  max_sessions: Int,
  keep_alive_timeout_ms: Int,
) -> Result(Nil, String)

@external(erlang, "http_pool_ffi", "configure")
fn configure(
  pool: Pool,
  max_sessions: Int,
  keep_alive_timeout_ms: Int,
) -> Result(Nil, String)

pub fn new() -> Pools {
  Pools(
    docker_run: Pool(DockerRun),
    cloudflare_email: Pool(CloudflareEmail),
    spam_classifier: Pool(SpamClassifier),
  )
}

pub fn start_all(pools: Pools, config: Config) -> Result(Nil, String) {
  use _ <- result.try(start(
    pools.docker_run,
    config.docker_run_max_sessions,
    config.keep_alive_timeout_ms,
  ))
  use _ <- result.try(start(
    pools.cloudflare_email,
    config.cloudflare_email_max_sessions,
    config.keep_alive_timeout_ms,
  ))
  start(pools.spam_classifier, 1, config.keep_alive_timeout_ms)
}

pub fn configure_all(pools: Pools, config: Config) -> Result(Nil, String) {
  use _ <- result.try(configure(
    pools.docker_run,
    config.docker_run_max_sessions,
    config.keep_alive_timeout_ms,
  ))
  use _ <- result.try(configure(
    pools.cloudflare_email,
    config.cloudflare_email_max_sessions,
    config.keep_alive_timeout_ms,
  ))
  configure(pools.spam_classifier, 1, config.keep_alive_timeout_ms)
}
