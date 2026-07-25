import glot_backend/system/database as db_helpers
import glot_backend/system/effect/adapter/database_ports
import glot_backend/system/effect/adapter/system_ports
import glot_backend/system/effect/adapter/transaction_port
import glot_backend/system/effect/cache_ports.{type CachePorts}
import glot_backend/system/effect/service_ports
import glot_backend/system/http/pool.{type Pools}
import pog

pub fn new(
  connection: pog.Connection,
  caches: CachePorts,
  http_pools: Pools,
) -> service_ports.ServicePorts {
  let db = db_helpers.new(connection)
  service_ports.ServicePorts(
    database: database_ports.new(db),
    system: system_ports.new(http_pools),
    caches: caches,
    transaction: transaction_port.new(db),
  )
}
