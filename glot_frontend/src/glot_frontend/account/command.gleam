import gleam/option
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/email_change_dto
import glot_core/auth/passkey_dto
import glot_core/auth/session_dto
import glot_frontend/api/response
import glot_frontend/ui/passkey

pub type Command(msg) {
  None
  Batch(List(Command(msg)))
  DetectPasskeySupport(fn(Bool) -> msg)
  GetAccount(fn(response.Response(account_dto.AccountResponse)) -> msg)
  GetSession(
    fn(response.Response(option.Option(session_dto.SessionResponse))) -> msg,
  )
  ListSessions(
    fn(response.Response(account_session_dto.ListAccountSessionsResponse)) ->
      msg,
  )
  ListPasskeys(
    fn(response.Response(passkey_dto.ListAccountPasskeysResponse)) -> msg,
  )
  UpdateAccount(
    account_dto.UpdateAccountRequest,
    fn(response.Response(account_dto.AccountResponse)) -> msg,
  )
  BeginEmailChange(
    email_change_dto.BeginEmailChangeRequest,
    fn(response.Response(Nil)) -> msg,
  )
  ConfirmEmailChange(
    email_change_dto.ConfirmEmailChangeRequest,
    fn(response.Response(account_dto.AccountResponse)) -> msg,
  )
  BeginPasskeyRegistration(
    fn(response.Response(passkey_dto.BeginPasskeyRegistrationResponse)) -> msg,
  )
  CreatePasskey(
    passkey_dto.BeginPasskeyRegistrationResponse,
    fn(Result(passkey.RegistrationResult, passkey.PasskeyError)) -> msg,
  )
  FinishPasskeyRegistration(
    passkey_dto.FinishPasskeyRegistrationRequest,
    fn(response.Response(Nil)) -> msg,
  )
  DeleteSession(
    account_session_dto.DeleteAccountSessionRequest,
    fn(response.Response(Nil)) -> msg,
  )
  DeletePasskey(
    passkey_dto.DeleteAccountPasskeyRequest,
    fn(response.Response(Nil)) -> msg,
  )
  Logout(fn(response.Response(Nil)) -> msg)
  ScheduleDelete(fn(response.Response(Nil)) -> msg)
  CancelDelete(fn(response.Response(Nil)) -> msg)
  Schedule(Int, msg)
  NavigateReplace(String)
}

pub fn none() -> Command(msg) {
  None
}

pub fn batch(commands: List(Command(msg))) -> Command(msg) {
  Batch(commands)
}
