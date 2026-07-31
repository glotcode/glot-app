import gleam/option
import glot_core/route
import glot_frontend/account/managed as account_managed
import glot_frontend/account/snippets/managed as account_snippets_managed
import glot_frontend/app/event.{type AppEvent, NoAppEvent}
import glot_frontend/app/public_page_command as command
import glot_frontend/app/public_page_message.{
  type Msg, AccountPageMsg, ContactPageMsg, EditorPageMsg, HomePageMsg,
  LoginPageMsg, ManageSnippetsPageMsg, SnippetsPageMsg,
}
import glot_frontend/app/public_page_state.{
  type Model, Account, Contact, Editor, Empty, Home, Login, ManageSnippets,
  Privacy, Snippets,
}
import glot_frontend/app/runtime
import glot_frontend/public/contact/managed as contact_managed
import glot_frontend/public/editor/lifecycle as editor_lifecycle
import glot_frontend/public/editor/managed as editor_managed
import glot_frontend/public/editor/metadata as editor_metadata
import glot_frontend/public/home/managed as home_managed
import glot_frontend/public/login/managed as login_managed
import glot_frontend/public/snippets/managed as snippets_managed

pub type Transition {
  Transition(
    model: Model,
    command: command.Command,
    event: AppEvent,
    metadata_changed: Bool,
  )
}

pub fn init(
  target: route.Route,
  session: runtime.SessionState,
) -> #(Model, command.Command) {
  case target {
    route.Public(public_route) -> init_public(public_route, session)
    route.Account(account_route) -> init_account(account_route)
    route.Admin(_) | route.NotFound(_) -> #(Empty, command.None)
  }
}

fn init_public(
  target: route.PublicRoute,
  session: runtime.SessionState,
) -> #(Model, command.Command) {
  case target {
    route.Home -> #(Home(home_managed.init()), command.None)
    route.Contact -> #(
      Contact(contact_managed.init(runtime.current_user_email(session))),
      command.None,
    )
    route.Privacy -> #(Privacy, command.None)
    route.Login -> {
      let #(model, next) = login_managed.init()
      #(Login(model), command.Login(next))
    }
    route.Snippets(after:, before:, username:) -> {
      let #(model, next) = snippets_managed.init(after:, before:, username:)
      #(Snippets(model), command.Snippets(next))
    }
    route.NewSnippet(language) -> {
      let #(model, next) =
        editor_managed.init(editor_lifecycle.NewEditor(language))
      #(Editor(model), command.Editor(next))
    }
    route.Snippet(slug) -> {
      let #(model, next) =
        editor_managed.init(editor_lifecycle.ExistingEditor(slug))
      #(Editor(model), command.Editor(next))
    }
  }
}

fn init_account(target: route.AccountRoute) -> #(Model, command.Command) {
  case target {
    route.AccountHome -> {
      let #(model, next) = account_managed.init()
      #(Account(model), command.Account(next))
    }
    route.AccountSnippets(after:, before:) -> {
      let #(model, next) = account_snippets_managed.init(after:, before:)
      #(ManageSnippets(model), command.ManageSnippets(next))
    }
  }
}

pub fn session_loaded(model: Model, session: runtime.SessionState) -> Model {
  case model {
    Contact(contact_model) ->
      Contact(contact_managed.session_loaded(
        contact_model,
        runtime.current_user_email(session),
      ))
    _ -> model
  }
}

pub fn update(
  model: Model,
  msg: Msg,
  session: runtime.SessionState,
) -> option.Option(Transition) {
  case model, msg {
    Home(page_model), HomePageMsg(page_msg) ->
      unchanged_metadata(
        Home(home_managed.update(page_model, page_msg)),
        command.None,
        NoAppEvent,
      )
    Contact(page_model), ContactPageMsg(page_msg) -> {
      let #(next_model, next) = contact_managed.update(page_model, page_msg)
      unchanged_metadata(Contact(next_model), command.Contact(next), NoAppEvent)
    }
    Login(page_model), LoginPageMsg(page_msg) -> {
      let #(next_model, next, event) =
        login_managed.update(page_model, page_msg)
      unchanged_metadata(Login(next_model), command.Login(next), event)
    }
    Account(page_model), AccountPageMsg(page_msg) -> {
      let #(next_model, next, event) =
        account_managed.update(page_model, page_msg)
      unchanged_metadata(Account(next_model), command.Account(next), event)
    }
    ManageSnippets(page_model), ManageSnippetsPageMsg(page_msg) -> {
      let #(next_model, next) =
        account_snippets_managed.update(page_model, page_msg)
      unchanged_metadata(
        ManageSnippets(next_model),
        command.ManageSnippets(next),
        NoAppEvent,
      )
    }
    Snippets(page_model), SnippetsPageMsg(page_msg) -> {
      let #(next_model, next) = snippets_managed.update(page_model, page_msg)
      unchanged_metadata(
        Snippets(next_model),
        command.Snippets(next),
        NoAppEvent,
      )
    }
    Editor(page_model), EditorPageMsg(page_msg) -> {
      let current_user_id = runtime.current_user_id(session)
      let #(next_model, next) =
        editor_managed.update(page_model, page_msg, current_user_id)
      option.Some(Transition(
        model: Editor(next_model),
        command: command.Editor(next),
        event: NoAppEvent,
        metadata_changed: editor_metadata.changed(page_model, next_model),
      ))
    }
    _, _ -> option.None
  }
}

fn unchanged_metadata(
  model: Model,
  next: command.Command,
  event: AppEvent,
) -> option.Option(Transition) {
  option.Some(Transition(model:, command: next, event:, metadata_changed: False))
}
