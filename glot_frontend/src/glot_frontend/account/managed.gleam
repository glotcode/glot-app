import gleam/option
import glot_core/loadable
import glot_frontend/account/command
import glot_frontend/account/message.{type Msg, RuntimeLoaded}
import glot_frontend/account/model.{
  type Model, Idle, IdlePasskeys, LoadingSessions, Model, PasskeySetupIdle,
}
import glot_frontend/account/update as account_update
import glot_frontend/app/event.{type AppEvent}
import glot_frontend/ui/delayed_loading

pub fn init() -> #(Model, command.Command(Msg)) {
  #(
    Model(
      account: loadable.Loading,
      username: "",
      status: Idle,
      account_loading_indicator: delayed_loading.idle(),
      danger_zone_expanded: False,
      passkey_supported: False,
      current_session_id: option.None,
      sessions: [],
      sessions_status: LoadingSessions,
      sessions_loading_indicator: delayed_loading.idle(),
      passkey_setup_status: PasskeySetupIdle,
      passkeys: [],
      passkeys_status: IdlePasskeys,
      passkeys_loading_indicator: delayed_loading.idle(),
    ),
    command.DetectPasskeySupport(RuntimeLoaded),
  )
}

pub fn update(
  model: Model,
  msg: Msg,
) -> #(Model, command.Command(Msg), AppEvent) {
  account_update.update(model, msg)
}
