import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/regexp
import glot_core/auth/account_dto
import glot_core/auth/account_session_dto
import glot_core/auth/email_change_dto
import glot_core/auth/passkey_dto
import glot_core/auth/refresh_session_dto
import glot_core/auth/session_dto
import glot_core/email/email_address_model
import glot_core/public_action
import glot_frontend/api/client
import glot_frontend/api/request
import glot_frontend/api/response
import lustre/effect

pub fn get_session(
  to_msg: fn(response.Response(option.Option(session_dto.SessionResponse))) ->
    msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.GetSessionAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    decode.optional(session_dto.decoder()),
    to_msg,
  )
}

pub fn refresh_session(
  to_msg: fn(response.Response(refresh_session_dto.RefreshSessionResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.RefreshSessionAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    refresh_session_dto.decoder(),
    to_msg,
  )
}

pub fn get_account(
  to_msg: fn(response.Response(account_dto.AccountResponse)) -> msg,
) -> effect.Effect(msg) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  let req = request.PublicRequest(public_action.GetAccountAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    account_dto.decoder(is_email),
    to_msg,
  )
}

pub fn list_account_sessions(
  to_msg: fn(response.Response(account_session_dto.ListAccountSessionsResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.ListAccountSessionsAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    account_session_dto.list_account_sessions_response_decoder(),
    to_msg,
  )
}

pub fn list_account_passkeys(
  to_msg: fn(response.Response(passkey_dto.ListAccountPasskeysResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.ListAccountPasskeysAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    passkey_dto.list_account_passkeys_response_decoder(),
    to_msg,
  )
}

pub fn logout(to_msg: fn(response.Response(Nil)) -> msg) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.LogoutAction, Nil)

  request.send_public(req, fn(_) { json.null() }, client.nil_decoder(), to_msg)
}

pub fn schedule_delete_account(
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.ScheduleDeleteAccountAction, Nil)

  request.send_public(req, fn(_) { json.null() }, client.nil_decoder(), to_msg)
}

pub fn cancel_delete_account(
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.CancelDeleteAccountAction, Nil)

  request.send_public(req, fn(_) { json.null() }, client.nil_decoder(), to_msg)
}

pub fn update_account(
  request: account_dto.UpdateAccountRequest,
  to_msg: fn(response.Response(account_dto.AccountResponse)) -> msg,
) -> effect.Effect(msg) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  let req = request.PublicRequest(public_action.UpdateAccountAction, request)

  request.send_public(
    req,
    fn(update_request) {
      json.object([
        #("username", json.string(update_request.username)),
      ])
    },
    account_dto.decoder(is_email),
    to_msg,
  )
}

pub fn begin_email_change(
  change: email_change_dto.BeginEmailChangeRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.BeginEmailChangeAction, change)
  request.send_public(
    req,
    email_change_dto.encode_begin_request,
    client.nil_decoder(),
    to_msg,
  )
}

pub fn confirm_email_change(
  change: email_change_dto.ConfirmEmailChangeRequest,
  to_msg: fn(response.Response(account_dto.AccountResponse)) -> msg,
) -> effect.Effect(msg) {
  let assert Ok(is_email) = regexp.from_string(email_address_model.pattern)
  let req =
    request.PublicRequest(public_action.ConfirmEmailChangeAction, change)
  request.send_public(
    req,
    email_change_dto.encode_confirm_request,
    account_dto.decoder(is_email),
    to_msg,
  )
}

pub fn begin_passkey_registration(
  to_msg: fn(response.Response(passkey_dto.BeginPasskeyRegistrationResponse)) ->
    msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.BeginPasskeyRegistrationAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    passkey_dto.begin_registration_response_decoder(),
    to_msg,
  )
}

pub fn begin_passkey_login(
  to_msg: fn(response.Response(passkey_dto.BeginPasskeyLoginResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.BeginPasskeyLoginAction, Nil)

  request.send_public(
    req,
    fn(_) { json.null() },
    passkey_dto.begin_login_response_decoder(),
    to_msg,
  )
}

pub fn delete_account_passkey(
  request: passkey_dto.DeleteAccountPasskeyRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.DeleteAccountPasskeyAction, request)

  request.send_public(
    req,
    passkey_dto.encode_delete_account_passkey_request,
    client.nil_decoder(),
    to_msg,
  )
}

pub fn delete_account_session(
  request: account_session_dto.DeleteAccountSessionRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.DeleteAccountSessionAction, request)

  request.send_public(
    req,
    account_session_dto.encode_delete_account_session_request,
    client.nil_decoder(),
    to_msg,
  )
}

pub fn finish_passkey_registration(
  request: passkey_dto.FinishPasskeyRegistrationRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(
      public_action.FinishPasskeyRegistrationAction,
      request,
    )

  request.send_public(
    req,
    passkey_dto.encode_finish_registration_request,
    client.nil_decoder(),
    to_msg,
  )
}

pub fn finish_passkey_login(
  request: passkey_dto.FinishPasskeyLoginRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.FinishPasskeyLoginAction, request)

  request.send_public(
    req,
    passkey_dto.encode_finish_login_request,
    client.nil_decoder(),
    to_msg,
  )
}
