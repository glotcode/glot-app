import glot_backend/auth/passkey/adapter/webauthn/ceremony as webauthn_ceremony
import glot_backend/email/adapter/cloudflare/sender as cloudflare_sender
import glot_backend/run_code/adapter/docker_run/client as docker_run_client
import glot_backend/system/effect/basic/basic_handlers
import glot_backend/system/effect/system_ports
import glot_backend/system/http/pool.{type Pools}

pub fn new(http_pools: Pools) -> system_ports.SystemPorts {
  system_ports.SystemPorts(
    basic: basic_handlers.new(),
    email: cloudflare_sender.new(http_pools.cloudflare_email),
    passkey: webauthn_ceremony.new(),
    run_code: docker_run_client.new(http_pools.docker_run),
  )
}
