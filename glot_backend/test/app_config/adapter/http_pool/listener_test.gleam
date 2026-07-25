import glot_backend/app_config/adapter/http_pool/listener
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/app_config/model/system_config
import glot_backend/system/http/pool

pub fn pool_config_maps_dynamic_config_test() {
  let config =
    dynamic_config.DynamicConfig(
      ..dynamic_config.empty(),
      http_pool: system_config.HttpPoolConfig(
        docker_run_max_sessions: 24,
        cloudflare_email_max_sessions: 6,
        keep_alive_timeout_ms: 90_000,
      ),
    )

  assert listener.pool_config(config)
    == pool.Config(
      docker_run_max_sessions: 24,
      cloudflare_email_max_sessions: 6,
      keep_alive_timeout_ms: 90_000,
    )
}
