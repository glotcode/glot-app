import glot_frontend/account/command as account_command
import glot_frontend/account/message as account_message
import glot_frontend/account/snippets/command as account_snippets_command
import glot_frontend/account/snippets/message as account_snippets_message
import glot_frontend/public/contact/command as contact_command
import glot_frontend/public/contact/message as contact_message
import glot_frontend/public/editor/command as editor_command
import glot_frontend/public/editor/message as editor_message
import glot_frontend/public/login/command as login_command
import glot_frontend/public/login/message as login_message
import glot_frontend/public/snippets/command as snippets_command
import glot_frontend/public/snippets/message as snippets_message

pub type Command {
  None
  Contact(contact_command.Command(contact_message.Msg))
  Login(login_command.Command(login_message.Msg))
  Account(account_command.Command(account_message.Msg))
  ManageSnippets(account_snippets_command.Command(account_snippets_message.Msg))
  Snippets(snippets_command.Command(snippets_message.Msg))
  Editor(editor_command.Command(editor_message.Msg))
}

pub fn none() -> Command {
  None
}

pub fn is_none(command: Command) -> Bool {
  case command {
    None
    | Contact(contact_command.None)
    | Login(login_command.None)
    | Account(account_command.None)
    | ManageSnippets(account_snippets_command.None)
    | Snippets(snippets_command.None)
    | Editor(editor_command.None) -> True
    _ -> False
  }
}
