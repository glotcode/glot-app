import glot_frontend/admin/config/auth_view as auth
import glot_frontend/admin/config/availability_view as availability
import glot_frontend/admin/config/cleanup_view as cleanup
import glot_frontend/admin/config/cloudflare_view as cloudflare
import glot_frontend/admin/config/debug_view as debug
import glot_frontend/admin/config/docker_run_view as docker_run
import glot_frontend/admin/config/email_view as email
import glot_frontend/admin/config/http_pool_view as http_pool
import glot_frontend/admin/config/language_version_cache_worker_view as language_version_cache_worker
import glot_frontend/admin/config/log_worker_view as log_worker
import glot_frontend/admin/config/passkey_view as passkey
import glot_frontend/admin/ui/layout as admin_layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/page_message.{
  type Msg, AuthMsg, AvailabilityMsg, CleanupMsg, CloudflareMsg, DebugMsg,
  DockerRunMsg, EmailMsg, HttpPoolMsg, LanguageVersionCacheWorkerMsg,
  LogWorkerMsg, PasskeyMsg,
}
import glot_frontend/admin/config/page_model.{type Model}

pub fn view(model: Model) -> Element(Msg) {
  admin_layout.page(title: "App config", intro: "", content: [
    html.div([attribute.class("admin-page__group")], [
      html.div([attribute.class("admin-page__section-grid")], [
        debug.view(model.debug) |> element.map(DebugMsg),
        availability.view(model.availability) |> element.map(AvailabilityMsg),
        auth.view(model.auth) |> element.map(AuthMsg),
        passkey.view(model.passkey) |> element.map(PasskeyMsg),
        cleanup.view(model.cleanup) |> element.map(CleanupMsg),
        log_worker.view(model.log_worker) |> element.map(LogWorkerMsg),
        http_pool.view(model.http_pool) |> element.map(HttpPoolMsg),
        language_version_cache_worker.view(model.language_version_cache_worker)
          |> element.map(LanguageVersionCacheWorkerMsg),
        docker_run.view(model.docker_run) |> element.map(DockerRunMsg),
        cloudflare.view(model.cloudflare) |> element.map(CloudflareMsg),
        email.view(model.email) |> element.map(EmailMsg),
      ]),
    ]),
  ])
}
