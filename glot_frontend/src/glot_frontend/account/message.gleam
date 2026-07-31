import gleam/option
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/passkey_dto
import glot_core/auth/session_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/delayed_loading
import glot_frontend/ui/passkey
import youid/uuid

pub type Msg {
  RuntimeLoaded(Bool)
  AccountLoaded(api_response.Response(account_dto.AccountResponse))
  AccountLoadingDelayElapsed(Generation(delayed_loading.Stream))
  SessionLoaded(
    api_response.Response(option.Option(session_dto.SessionResponse)),
  )
  AccountSessionsLoaded(
    api_response.Response(account_session_dto.ListAccountSessionsResponse),
  )
  SessionsLoadingDelayElapsed(Generation(delayed_loading.Stream))
  AccountPasskeysLoaded(
    api_response.Response(passkey_dto.ListAccountPasskeysResponse),
  )
  PasskeysLoadingDelayElapsed(Generation(delayed_loading.Stream))
  UsernameChanged(String)
  UsernameSubmitted
  AccountUpdated(api_response.Response(account_dto.AccountResponse))
  BeginPasskeySubmitted
  BeganPasskeyRegistration(
    api_response.Response(passkey_dto.BeginPasskeyRegistrationResponse),
  )
  PasskeyRegistrationCreated(
    uuid.Uuid,
    Result(passkey.RegistrationResult, passkey.PasskeyError),
  )
  FinishedPasskeyRegistration(api_response.Response(Nil))
  DeleteSessionSubmitted(uuid.Uuid)
  DeletedSession(uuid.Uuid, api_response.Response(Nil))
  DeletePasskeySubmitted(uuid.Uuid)
  DeletedPasskey(uuid.Uuid, api_response.Response(Nil))
  LogoutSubmitted
  ScheduleDeleteSubmitted
  DeleteScheduled(api_response.Response(Nil))
  CancelDeleteSubmitted
  DeleteCanceled(api_response.Response(Nil))
  ToggleDangerZone
  LoggedOut(api_response.Response(Nil))
}
