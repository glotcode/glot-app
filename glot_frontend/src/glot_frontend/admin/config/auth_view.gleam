import gleam/option
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/auth.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/auth_policy.{
  type Field, HeartbeatInterval, LoginTokenMaxAge, PreviousTokenGrace,
  SessionCookieMaxAge, SessionIdleTimeout, SessionRefreshInterval,
  SessionTokenMaxAge,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  section_view.card(
    title: "Auth",
    subtitle: "Controls login token expiry, session lifetime, rotation policy, and frontend heartbeat cadence.",
    state: model.mutation_state,
    dirty:,
    idle_badge: option.None,
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "Login token max age",
        "Seconds before a login token expires.",
        model.draft.login_token_max_age,
        LoginTokenMaxAge,
      ),
      input(
        "Session max lifetime",
        "Absolute maximum seconds since creation before a session becomes invalid.",
        model.draft.session_token_max_age,
        SessionTokenMaxAge,
      ),
      input(
        "Session idle timeout",
        "Seconds since the last successful session heartbeat before a session becomes invalid.",
        model.draft.session_idle_timeout_seconds,
        SessionIdleTimeout,
      ),
      input(
        "Session cookie max age",
        "Seconds used when setting the signed session cookie.",
        model.draft.session_cookie_max_age,
        SessionCookieMaxAge,
      ),
      input(
        "Session rotation interval",
        "Minimum seconds between backend session token rotations.",
        model.draft.session_refresh_interval_seconds,
        SessionRefreshInterval,
      ),
      input(
        "Previous token grace window",
        "Seconds to keep accepting the previous session token after a rotation.",
        model.draft.session_previous_token_grace_seconds,
        PreviousTokenGrace,
      ),
      input(
        "Heartbeat cadence",
        "Seconds the frontend should wait before sending the next session heartbeat.",
        model.draft.session_heartbeat_interval_seconds,
        HeartbeatInterval,
      ),
    ]),
    footer: section_view.footer(
      load_state: model.load_state,
      mutation_state: model.mutation_state,
      dirty:,
      idle_message: option.None,
      reset_msg: ResetClicked,
      save_msg: SaveClicked,
    ),
  )
}

fn input(
  label: String,
  help: String,
  value: String,
  field: Field,
) -> Element(Msg) {
  admin_form.text_input(
    label:,
    help:,
    value:,
    placeholder: "",
    on_input: fn(value) { FieldChanged(field, value) },
  )
}
