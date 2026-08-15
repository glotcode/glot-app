import gleam/option
import glot_frontend/api/public as public_api
import glot_frontend/platform/app_dialog
import glot_frontend/platform/spa_navigation
import glot_frontend/platform/ssr_data
import glot_frontend/platform/timer
import glot_frontend/public/editor/draft_store
import glot_frontend/public/editor/ports
import glot_frontend/public/editor/settings_store
import lustre/effect

pub fn new() -> ports.Ports(msg) {
  ports.Ports(
    load_environment: fn(complete) {
      effect.from(fn(dispatch) {
        dispatch(complete(ssr_data.take(), settings_store.load()))
      })
    },
    load_draft: fn(target, complete) {
      effect.from(fn(dispatch) { dispatch(complete(draft_store.load(target))) })
    },
    get_snippet: public_api.get_snippet,
    run_code: public_api.run_code,
    cancel_run: public_api.cancel_run,
    get_language_version: public_api.get_language_version,
    create_snippet: public_api.create_snippet,
    update_snippet: public_api.update_snippet,
    save_draft: draft_store.save,
    clear_draft: draft_store.clear,
    save_settings: settings_store.save,
    open_dialog: app_dialog.open,
    open_dialog_next_frame: app_dialog.open_next_frame,
    close_dialog: app_dialog.close,
    focus: app_dialog.focus,
    blur: app_dialog.blur,
    navigate: fn(path) { spa_navigation.push(path, option.None) },
    schedule: fn(milliseconds, msg) {
      effect.from(fn(dispatch) {
        timer.schedule(milliseconds, fn() { dispatch(msg) })
      })
    },
  )
}
