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

pub type Msg {
  DebugMsg(debug.Msg)
  AvailabilityMsg(availability.Msg)
  AuthMsg(auth.Msg)
  PasskeyMsg(passkey.Msg)
  CleanupMsg(cleanup.Msg)
  LogWorkerMsg(log_worker.Msg)
  HttpPoolMsg(http_pool.Msg)
  LanguageVersionCacheWorkerMsg(language_version_cache_worker.Msg)
  DockerRunMsg(docker_run.Msg)
  CloudflareMsg(cloudflare.Msg)
  EmailMsg(email.Msg)
}
