import glot_frontend/api/account as account_api
import glot_frontend/api/public as public_api
import glot_frontend/platform/passkey
import glot_frontend/platform/spa_navigation
import glot_frontend/public/login/ports
import lustre/effect

pub fn new() -> ports.Ports(msg) {
  ports.Ports(
    detect_passkey_support: fn(complete) {
      effect.from(fn(dispatch) { dispatch(complete(passkey.is_supported())) })
    },
    send_login_token: public_api.send_login_token,
    login: public_api.login,
    begin_passkey_login: account_api.begin_passkey_login,
    authenticate_passkey: passkey.begin_authentication,
    finish_passkey_login: account_api.finish_passkey_login,
    navigate_replace: spa_navigation.replace,
  )
}
