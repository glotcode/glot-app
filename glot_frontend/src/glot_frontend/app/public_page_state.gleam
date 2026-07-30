import glot_frontend/account/model as account_model
import glot_frontend/account/snippets/model as account_snippets_model
import glot_frontend/public/contact/model as contact_model
import glot_frontend/public/editor/model as editor_model
import glot_frontend/public/home/model as home_model
import glot_frontend/public/login/model as login_model
import glot_frontend/public/snippets/model as snippets_model

pub type Model {
  Home(home_model.Model)
  Contact(contact_model.Model)
  Privacy
  Login(login_model.Model)
  Account(account_model.Model)
  ManageSnippets(account_snippets_model.Model)
  Snippets(snippets_model.Model)
  Editor(editor_model.Model)
  Empty
}
