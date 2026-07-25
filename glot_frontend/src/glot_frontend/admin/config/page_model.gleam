import glot_frontend/admin/config/auth
import glot_frontend/admin/config/availability
import glot_frontend/admin/config/cleanup
import glot_frontend/admin/config/cloudflare
import glot_frontend/admin/config/debug
import glot_frontend/admin/config/docker_run
import glot_frontend/admin/config/email
import glot_frontend/admin/config/http_pool
import glot_frontend/admin/config/language_version_cache_worker
import glot_frontend/admin/config/log_worker
import glot_frontend/admin/config/passkey

pub type Model {
  Model(
    debug: debug.Model,
    availability: availability.Model,
    auth: auth.Model,
    passkey: passkey.Model,
    cleanup: cleanup.Model,
    log_worker: log_worker.Model,
    http_pool: http_pool.Model,
    language_version_cache_worker: language_version_cache_worker.Model,
    docker_run: docker_run.Model,
    cloudflare: cloudflare.Model,
    email: email.Model,
  )
}
