import gleam/option
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/email_change_dto
import glot_core/auth/passkey_dto
import glot_core/auth/session_dto
import glot_frontend/api/response
import glot_frontend/ui/passkey
import lustre/effect.{type Effect}

pub type Ports(msg) {
  Ports(
    detect_passkey_support: fn(fn(Bool) -> msg) -> Effect(msg),
    get_account: fn(fn(response.Response(account_dto.AccountResponse)) -> msg) ->
      Effect(msg),
    get_session: fn(
      fn(response.Response(option.Option(session_dto.SessionResponse))) -> msg,
    ) -> Effect(msg),
    list_sessions: fn(
      fn(response.Response(account_session_dto.ListAccountSessionsResponse)) ->
        msg,
    ) -> Effect(msg),
    list_passkeys: fn(
      fn(response.Response(passkey_dto.ListAccountPasskeysResponse)) -> msg,
    ) -> Effect(msg),
    update_account: fn(
      account_dto.UpdateAccountRequest,
      fn(response.Response(account_dto.AccountResponse)) -> msg,
    ) -> Effect(msg),
    begin_email_change: fn(
      email_change_dto.BeginEmailChangeRequest,
      fn(response.Response(Nil)) -> msg,
    ) -> Effect(msg),
    confirm_email_change: fn(
      email_change_dto.ConfirmEmailChangeRequest,
      fn(response.Response(account_dto.AccountResponse)) -> msg,
    ) -> Effect(msg),
    begin_passkey_registration: fn(
      fn(response.Response(passkey_dto.BeginPasskeyRegistrationResponse)) -> msg,
    ) -> Effect(msg),
    create_passkey: fn(
      passkey_dto.BeginPasskeyRegistrationResponse,
      fn(Result(passkey.RegistrationResult, passkey.PasskeyError)) -> msg,
    ) -> Effect(msg),
    finish_passkey_registration: fn(
      passkey_dto.FinishPasskeyRegistrationRequest,
      fn(response.Response(Nil)) -> msg,
    ) -> Effect(msg),
    delete_session: fn(
      account_session_dto.DeleteAccountSessionRequest,
      fn(response.Response(Nil)) -> msg,
    ) -> Effect(msg),
    delete_passkey: fn(
      passkey_dto.DeleteAccountPasskeyRequest,
      fn(response.Response(Nil)) -> msg,
    ) -> Effect(msg),
    logout: fn(fn(response.Response(Nil)) -> msg) -> Effect(msg),
    schedule_delete: fn(fn(response.Response(Nil)) -> msg) -> Effect(msg),
    cancel_delete: fn(fn(response.Response(Nil)) -> msg) -> Effect(msg),
    schedule: fn(Int, msg) -> Effect(msg),
    navigate_replace: fn(String) -> Effect(msg),
  )
}
