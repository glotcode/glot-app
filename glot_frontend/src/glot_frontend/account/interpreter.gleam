import gleam/list
import glot_frontend/account/command
import glot_frontend/account/ports
import lustre/effect.{type Effect}

pub fn run(
  command: command.Command(msg),
  using ports: ports.Ports(msg),
) -> Effect(msg) {
  case command {
    command.None -> effect.none()
    command.Batch(commands) ->
      effect.batch(list.map(commands, fn(command) { run(command, ports) }))
    command.DetectPasskeySupport(complete) ->
      ports.detect_passkey_support(complete)
    command.GetAccount(complete) -> ports.get_account(complete)
    command.GetSession(complete) -> ports.get_session(complete)
    command.ListSessions(complete) -> ports.list_sessions(complete)
    command.ListPasskeys(complete) -> ports.list_passkeys(complete)
    command.UpdateAccount(request, complete) ->
      ports.update_account(request, complete)
    command.BeginEmailChange(request, complete) ->
      ports.begin_email_change(request, complete)
    command.ConfirmEmailChange(request, complete) ->
      ports.confirm_email_change(request, complete)
    command.BeginPasskeyRegistration(complete) ->
      ports.begin_passkey_registration(complete)
    command.CreatePasskey(options, complete) ->
      ports.create_passkey(options, complete)
    command.FinishPasskeyRegistration(request, complete) ->
      ports.finish_passkey_registration(request, complete)
    command.DeleteSession(request, complete) ->
      ports.delete_session(request, complete)
    command.DeletePasskey(request, complete) ->
      ports.delete_passkey(request, complete)
    command.Logout(complete) -> ports.logout(complete)
    command.ScheduleDelete(complete) -> ports.schedule_delete(complete)
    command.CancelDelete(complete) -> ports.cancel_delete(complete)
    command.Schedule(milliseconds, msg) -> ports.schedule(milliseconds, msg)
    command.NavigateReplace(path) -> ports.navigate_replace(path)
  }
}
