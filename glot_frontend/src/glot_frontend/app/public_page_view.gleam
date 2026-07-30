import gleam/time/timestamp.{type Timestamp}
import glot_frontend/account/snippets/view as account_snippets_view
import glot_frontend/account/view as account_view
import glot_frontend/app/public_page_message.{
  type Msg, AccountPageMsg, ContactPageMsg, EditorPageMsg, HomePageMsg,
  LoginPageMsg, ManageSnippetsPageMsg, SnippetsPageMsg,
}
import glot_frontend/app/public_page_state.{
  type Model, Account, Contact, Editor, Empty, Home, Login, ManageSnippets,
  Privacy, Snippets,
}
import glot_frontend/app/runtime
import glot_frontend/public/contact/page as contact_page
import glot_frontend/public/editor/view as editor_view
import glot_frontend/public/home/view as home_view
import glot_frontend/public/login/view as login_view
import glot_frontend/public/snippets/view as snippets_view
import glot_frontend/ui/not_found
import glot_web/page/privacy
import lustre/element.{type Element}

pub fn view(
  model: Model,
  session: runtime.SessionState,
  now: Timestamp,
) -> Element(Msg) {
  case model {
    Home(page) -> home_view.view(page) |> element.map(HomePageMsg)
    Contact(page) -> contact_page.view(page) |> element.map(ContactPageMsg)
    Privacy -> privacy.view()
    Login(page) -> login_view.view(page) |> element.map(LoginPageMsg)
    Account(page) -> account_view.view(page, now) |> element.map(AccountPageMsg)
    ManageSnippets(page) ->
      account_snippets_view.view(page, now)
      |> element.map(ManageSnippetsPageMsg)
    Snippets(page) ->
      snippets_view.view(page, now) |> element.map(SnippetsPageMsg)
    Editor(page) ->
      editor_view.view(page, runtime.current_user_id(session), now)
      |> element.map(EditorPageMsg)
    Empty -> not_found.view()
  }
}
