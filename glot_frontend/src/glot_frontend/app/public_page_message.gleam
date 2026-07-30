import glot_frontend/account/message as account_message
import glot_frontend/account/snippets/message as account_snippets_message
import glot_frontend/public/contact/message as contact_message
import glot_frontend/public/editor/message as editor_message
import glot_frontend/public/home/message as home_message
import glot_frontend/public/login/message as login_message
import glot_frontend/public/snippets/message as snippets_message

pub type Msg {
  HomePageMsg(home_message.Msg)
  ContactPageMsg(contact_message.Msg)
  LoginPageMsg(login_message.Msg)
  AccountPageMsg(account_message.Msg)
  ManageSnippetsPageMsg(account_snippets_message.Msg)
  SnippetsPageMsg(snippets_message.Msg)
  EditorPageMsg(editor_message.Msg)
}

pub fn affects_metadata(msg: Msg) -> Bool {
  case msg {
    EditorPageMsg(editor_msg) -> editor_message.affects_metadata(editor_msg)
    HomePageMsg(_)
    | ContactPageMsg(_)
    | LoginPageMsg(_)
    | AccountPageMsg(_)
    | ManageSnippetsPageMsg(_)
    | SnippetsPageMsg(_) -> False
  }
}
