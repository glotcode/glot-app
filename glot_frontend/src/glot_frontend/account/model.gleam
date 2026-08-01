import gleam/option
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/passkey_dto
import glot_core/loadable
import glot_frontend/ui/delayed_loading
import youid/uuid

pub type Model {
  Model(
    account: loadable.Loadable(account_dto.AccountResponse),
    username: String,
    status: Status,
    account_loading_indicator: delayed_loading.State,
    danger_zone_expanded: Bool,
    passkey_supported: Bool,
    current_session_id: option.Option(uuid.Uuid),
    sessions: List(account_session_dto.AccountSessionResponse),
    sessions_status: SessionsStatus,
    sessions_loading_indicator: delayed_loading.State,
    passkey_setup_status: PasskeySetupStatus,
    passkeys: List(passkey_dto.AccountPasskeyResponse),
    passkeys_status: PasskeysStatus,
    passkeys_loading_indicator: delayed_loading.State,
  )
}

pub type Status {
  Idle
  Saving
  LoggingOut
  SchedulingDelete
  CancelingDelete
  Saved
  UsernameError(String)
  DeleteError(String)
  LogoutError(String)
}

pub type PasskeySetupStatus {
  PasskeySetupIdle
  StartingPasskeySetup
  CreatingPasskey
  SavingPasskey
  PasskeySaved
  PasskeySetupError(String)
}

pub type SessionsStatus {
  LoadingSessions
  IdleSessions
  DeletingSession(uuid.Uuid)
  SessionsError(String)
}

pub type PasskeysStatus {
  LoadingPasskeys
  IdlePasskeys
  DeletingPasskey(uuid.Uuid)
  PasskeysError(String)
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.account)
  || delayed_loading.is_visible(model.account_loading_indicator)
}
