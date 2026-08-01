import glot_frontend/account/ports
import glot_frontend/api/account as account_api
import glot_frontend/platform/passkey
import glot_frontend/platform/spa_navigation
import glot_frontend/platform/timer
import lustre/effect

pub fn new() -> ports.Ports(msg) {
  ports.Ports(
    detect_passkey_support: fn(complete) {
      effect.from(fn(dispatch) { dispatch(complete(passkey.is_supported())) })
    },
    get_account: account_api.get_account,
    get_session: account_api.get_session,
    list_sessions: account_api.list_account_sessions,
    list_passkeys: account_api.list_account_passkeys,
    update_account: account_api.update_account,
    begin_passkey_registration: account_api.begin_passkey_registration,
    create_passkey: passkey.begin_registration,
    finish_passkey_registration: account_api.finish_passkey_registration,
    delete_session: account_api.delete_account_session,
    delete_passkey: account_api.delete_account_passkey,
    logout: account_api.logout,
    schedule_delete: account_api.schedule_delete_account,
    cancel_delete: account_api.cancel_delete_account,
    schedule: fn(milliseconds, msg) {
      effect.from(fn(dispatch) {
        timer.schedule(milliseconds, fn() { dispatch(msg) })
      })
    },
    navigate_replace: spa_navigation.replace,
  )
}
