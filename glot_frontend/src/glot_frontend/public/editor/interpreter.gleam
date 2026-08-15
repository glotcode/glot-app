import gleam/list
import glot_frontend/public/editor/command
import glot_frontend/public/editor/ports
import lustre/effect.{type Effect}

pub fn run(
  command: command.Command(msg),
  using ports: ports.Ports(msg),
) -> Effect(msg) {
  case command {
    command.None -> effect.none()
    command.Batch(commands) ->
      effect.batch(list.map(commands, fn(command) { run(command, ports) }))
    command.LoadEnvironment(complete) -> ports.load_environment(complete)
    command.LoadDraft(target, complete) -> ports.load_draft(target, complete)
    command.GetSnippet(request, complete) ->
      ports.get_snippet(request, complete)
    command.RunCode(request, complete) -> ports.run_code(request, complete)
    command.CancelRun -> ports.cancel_run()
    command.GetLanguageVersion(request, complete) ->
      ports.get_language_version(request, complete)
    command.CreateSnippet(request, complete) ->
      ports.create_snippet(request, complete)
    command.UpdateSnippet(request, complete) ->
      ports.update_snippet(request, complete)
    command.SaveDraft(write) -> ports.save_draft(write)
    command.ClearDraft(target) -> ports.clear_draft(target)
    command.SaveSettings(value) -> ports.save_settings(value)
    command.OpenDialog(id) -> ports.open_dialog(id)
    command.OpenDialogNextFrame(id) -> ports.open_dialog_next_frame(id)
    command.CloseDialog(id) -> ports.close_dialog(id)
    command.Focus(id) -> ports.focus(id)
    command.Blur(id) -> ports.blur(id)
    command.Navigate(path) -> ports.navigate(path)
    command.Schedule(milliseconds, msg) -> ports.schedule(milliseconds, msg)
  }
}
