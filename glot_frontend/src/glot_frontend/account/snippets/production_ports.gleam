import glot_frontend/account/snippets/ports
import glot_frontend/api/public as public_api
import glot_frontend/platform/app_dialog
import glot_frontend/platform/spa_navigation
import glot_frontend/platform/timer
import lustre/effect

pub fn new() -> ports.Ports(msg) {
  ports.Ports(
    list_snippets: public_api.list_session_snippets,
    delete_snippet: public_api.delete_snippet,
    open_dialog: app_dialog.open,
    close_dialog: app_dialog.close,
    navigate: spa_navigation.push,
    schedule: fn(milliseconds, msg) {
      effect.from(fn(dispatch) {
        timer.schedule(milliseconds, fn() { dispatch(msg) })
      })
    },
  )
}
