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
import glot_frontend/admin/config/section
import glot_frontend/admin/config/spam_classifier

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
    spam_classifier: spam_classifier.Model,
    cloudflare: cloudflare.Model,
    email: email.Model,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  section.is_presentable(model.debug)
  && section.is_presentable(model.availability)
  && section.is_presentable(model.auth)
  && section.is_presentable(model.passkey)
  && section.is_presentable(model.cleanup)
  && section.is_presentable(model.log_worker)
  && section.is_presentable(model.http_pool)
  && section.is_presentable(model.language_version_cache_worker)
  && section.is_presentable(model.docker_run)
  && section.is_presentable(model.spam_classifier)
  && section.is_presentable(model.cloudflare)
  && section.is_presentable(model.email)
}
