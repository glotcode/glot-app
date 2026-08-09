import glot_frontend/account/account_access_workflow
import glot_frontend/account/command
import glot_frontend/account/email_change_workflow
import glot_frontend/account/initialization_workflow
import glot_frontend/account/message.{
  type Msg, AccountLoaded, AccountLoadingDelayElapsed, AccountPasskeysLoaded,
  AccountSessionsLoaded, AccountUpdated, BeganPasskeyRegistration,
  BeginEmailChangeSubmitted, BeginPasskeySubmitted, CancelDeleteSubmitted,
  ConfirmEmailChangeSubmitted, DeleteCanceled, DeletePasskeySubmitted,
  DeleteScheduled, DeleteSessionSubmitted, DeletedPasskey, DeletedSession,
  EmailChangeBegun, EmailChangeConfirmed, EmailCodeChanged, EmailInputChanged,
  FinishedPasskeyRegistration, LoggedOut, LogoutSubmitted,
  PasskeyRegistrationCreated, PasskeysLoadingDelayElapsed, RuntimeLoaded,
  ScheduleDeleteSubmitted, SessionLoaded, SessionsLoadingDelayElapsed,
  ToggleDangerZone, UsernameChanged, UsernameSubmitted,
}
import glot_frontend/account/model.{type Model}
import glot_frontend/account/passkeys_workflow
import glot_frontend/account/profile_workflow
import glot_frontend/account/sessions_workflow
import glot_frontend/app/event as app_event

pub fn update(
  model: Model,
  msg: Msg,
) -> #(Model, command.Command(Msg), app_event.AppEvent) {
  case msg {
    RuntimeLoaded(_)
    | AccountLoaded(_)
    | AccountLoadingDelayElapsed(_)
    | SessionLoaded(_) -> initialization_workflow.update(model, msg)

    AccountSessionsLoaded(_)
    | SessionsLoadingDelayElapsed(_)
    | DeleteSessionSubmitted(_)
    | DeletedSession(_, _) -> sessions_workflow.update(model, msg)

    AccountPasskeysLoaded(_)
    | PasskeysLoadingDelayElapsed(_)
    | BeginPasskeySubmitted
    | BeganPasskeyRegistration(_)
    | PasskeyRegistrationCreated(_, _)
    | FinishedPasskeyRegistration(_)
    | DeletePasskeySubmitted(_)
    | DeletedPasskey(_, _) -> passkeys_workflow.update(model, msg)

    UsernameChanged(_) | UsernameSubmitted | AccountUpdated(_) ->
      profile_workflow.update(model, msg)

    EmailInputChanged(_)
    | EmailCodeChanged(_)
    | BeginEmailChangeSubmitted
    | EmailChangeBegun(_)
    | ConfirmEmailChangeSubmitted
    | EmailChangeConfirmed(_) -> email_change_workflow.update(model, msg)

    LogoutSubmitted
    | ScheduleDeleteSubmitted
    | DeleteScheduled(_)
    | CancelDeleteSubmitted
    | DeleteCanceled(_)
    | ToggleDangerZone
    | LoggedOut(_) -> account_access_workflow.update(model, msg)
  }
}
