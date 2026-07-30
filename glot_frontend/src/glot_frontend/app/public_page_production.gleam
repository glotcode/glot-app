import glot_frontend/account/interpreter as account_interpreter
import glot_frontend/account/production_ports as account_production_ports
import glot_frontend/account/snippets/interpreter as account_snippets_interpreter
import glot_frontend/account/snippets/production_ports as account_snippets_production_ports
import glot_frontend/app/public_page_command as command
import glot_frontend/app/public_page_message.{
  type Msg, AccountPageMsg, ContactPageMsg, EditorPageMsg, LoginPageMsg,
  ManageSnippetsPageMsg, SnippetsPageMsg,
}
import glot_frontend/public/contact/interpreter as contact_interpreter
import glot_frontend/public/contact/production_ports as contact_production_ports
import glot_frontend/public/editor/interpreter as editor_interpreter
import glot_frontend/public/editor/production_ports as editor_production_ports
import glot_frontend/public/login/interpreter as login_interpreter
import glot_frontend/public/login/production_ports as login_production_ports
import glot_frontend/public/snippets/interpreter as snippets_interpreter
import glot_frontend/public/snippets/production_ports as snippets_production_ports
import lustre/effect.{type Effect}

pub fn run(command: command.Command) -> Effect(Msg) {
  case command {
    command.None -> effect.none()
    command.Contact(next) ->
      contact_interpreter.run(next, using: contact_production_ports.new())
      |> effect.map(ContactPageMsg)
    command.Login(next) ->
      login_interpreter.run(next, using: login_production_ports.new())
      |> effect.map(LoginPageMsg)
    command.Account(next) ->
      account_interpreter.run(next, using: account_production_ports.new())
      |> effect.map(AccountPageMsg)
    command.ManageSnippets(next) ->
      account_snippets_interpreter.run(
        next,
        using: account_snippets_production_ports.new(),
      )
      |> effect.map(ManageSnippetsPageMsg)
    command.Snippets(next) ->
      snippets_interpreter.run(next, using: snippets_production_ports.new())
      |> effect.map(SnippetsPageMsg)
    command.Editor(next) ->
      editor_interpreter.run(next, using: editor_production_ports.new())
      |> effect.map(EditorPageMsg)
  }
}
