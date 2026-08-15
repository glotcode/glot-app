import glot_frontend/admin/command as admin_effect
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
import glot_frontend/admin/config/spam_classifier

import glot_frontend/admin/config/page_message.{
  type Msg, AuthMsg, AvailabilityMsg, CleanupMsg, CloudflareMsg, DebugMsg,
  DockerRunMsg, EmailMsg, HttpPoolMsg, LanguageVersionCacheWorkerMsg,
  LogWorkerMsg, PasskeyMsg, SpamClassifierMsg,
}
import glot_frontend/admin/config/page_model.{type Model, Model}

pub fn init() -> #(Model, admin_effect.Command(Msg)) {
  #(
    Model(
      debug: debug.init(),
      availability: availability.init(),
      auth: auth.init(),
      passkey: passkey.init(),
      cleanup: cleanup.init(),
      log_worker: log_worker.init(),
      http_pool: http_pool.init(),
      language_version_cache_worker: language_version_cache_worker.init(),
      docker_run: docker_run.init(),
      spam_classifier: spam_classifier.init(),
      cloudflare: cloudflare.init(),
      email: email.init(),
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  let #(debug, debug_effect) = debug.ensure_loaded(model.debug)
  let #(availability, availability_effect) =
    availability.ensure_loaded(model.availability)
  let #(auth, auth_effect) = auth.ensure_loaded(model.auth)
  let #(passkey, passkey_effect) = passkey.ensure_loaded(model.passkey)
  let #(cleanup, cleanup_effect) = cleanup.ensure_loaded(model.cleanup)
  let #(log_worker, log_worker_effect) =
    log_worker.ensure_loaded(model.log_worker)
  let #(http_pool, http_pool_effect) = http_pool.ensure_loaded(model.http_pool)
  let #(language_version_cache_worker, language_version_cache_worker_effect) =
    language_version_cache_worker.ensure_loaded(
      model.language_version_cache_worker,
    )
  let #(docker_run, docker_run_effect) =
    docker_run.ensure_loaded(model.docker_run)
  let #(spam_classifier, spam_classifier_effect) =
    spam_classifier.ensure_loaded(model.spam_classifier)
  let #(cloudflare, cloudflare_effect) =
    cloudflare.ensure_loaded(model.cloudflare)
  let #(email, email_effect) = email.ensure_loaded(model.email)

  #(
    Model(
      debug:,
      availability:,
      auth:,
      passkey:,
      cleanup:,
      log_worker:,
      http_pool:,
      language_version_cache_worker:,
      docker_run:,
      spam_classifier:,
      cloudflare:,
      email:,
    ),
    admin_effect.batch([
      admin_effect.map(debug_effect, DebugMsg),
      admin_effect.map(availability_effect, AvailabilityMsg),
      admin_effect.map(auth_effect, AuthMsg),
      admin_effect.map(passkey_effect, PasskeyMsg),
      admin_effect.map(cleanup_effect, CleanupMsg),
      admin_effect.map(log_worker_effect, LogWorkerMsg),
      admin_effect.map(http_pool_effect, HttpPoolMsg),
      admin_effect.map(
        language_version_cache_worker_effect,
        LanguageVersionCacheWorkerMsg,
      ),
      admin_effect.map(docker_run_effect, DockerRunMsg),
      admin_effect.map(spam_classifier_effect, SpamClassifierMsg),
      admin_effect.map(cloudflare_effect, CloudflareMsg),
      admin_effect.map(email_effect, EmailMsg),
    ]),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    DebugMsg(debug_msg) -> {
      let #(child, child_effect) = debug.update(model.debug, debug_msg)
      #(Model(..model, debug: child), admin_effect.map(child_effect, DebugMsg))
    }
    AvailabilityMsg(child_msg) -> {
      let #(child, child_effect) =
        availability.update(model.availability, child_msg)
      #(
        Model(..model, availability: child),
        admin_effect.map(child_effect, AvailabilityMsg),
      )
    }
    AuthMsg(child_msg) -> {
      let #(child, child_effect) = auth.update(model.auth, child_msg)
      #(Model(..model, auth: child), admin_effect.map(child_effect, AuthMsg))
    }
    PasskeyMsg(child_msg) -> {
      let #(child, child_effect) = passkey.update(model.passkey, child_msg)
      #(
        Model(..model, passkey: child),
        admin_effect.map(child_effect, PasskeyMsg),
      )
    }
    CleanupMsg(child_msg) -> {
      let #(child, child_effect) = cleanup.update(model.cleanup, child_msg)
      #(
        Model(..model, cleanup: child),
        admin_effect.map(child_effect, CleanupMsg),
      )
    }
    LogWorkerMsg(child_msg) -> {
      let #(child, child_effect) =
        log_worker.update(model.log_worker, child_msg)
      #(
        Model(..model, log_worker: child),
        admin_effect.map(child_effect, LogWorkerMsg),
      )
    }
    HttpPoolMsg(child_msg) -> {
      let #(child, child_effect) = http_pool.update(model.http_pool, child_msg)
      #(
        Model(..model, http_pool: child),
        admin_effect.map(child_effect, HttpPoolMsg),
      )
    }
    LanguageVersionCacheWorkerMsg(child_msg) -> {
      let #(child, child_effect) =
        language_version_cache_worker.update(
          model.language_version_cache_worker,
          child_msg,
        )
      #(
        Model(..model, language_version_cache_worker: child),
        admin_effect.map(child_effect, LanguageVersionCacheWorkerMsg),
      )
    }
    DockerRunMsg(child_msg) -> {
      let #(child, child_effect) =
        docker_run.update(model.docker_run, child_msg)
      #(
        Model(..model, docker_run: child),
        admin_effect.map(child_effect, DockerRunMsg),
      )
    }
    SpamClassifierMsg(child_msg) -> {
      let #(child, child_effect) =
        spam_classifier.update(model.spam_classifier, child_msg)
      #(
        Model(..model, spam_classifier: child),
        admin_effect.map(child_effect, SpamClassifierMsg),
      )
    }
    CloudflareMsg(child_msg) -> {
      let #(child, child_effect) =
        cloudflare.update(model.cloudflare, child_msg)
      #(
        Model(..model, cloudflare: child),
        admin_effect.map(child_effect, CloudflareMsg),
      )
    }
    EmailMsg(child_msg) -> {
      let #(child, child_effect) = email.update(model.email, child_msg)
      #(Model(..model, email: child), admin_effect.map(child_effect, EmailMsg))
    }
  }
}
