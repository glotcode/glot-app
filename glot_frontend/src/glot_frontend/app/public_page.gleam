import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/route
import glot_frontend/app/event.{type AppEvent}
import glot_frontend/app/public_page_actions
import glot_frontend/app/public_page_command
import glot_frontend/app/public_page_managed
import glot_frontend/app/public_page_message
import glot_frontend/app/public_page_metadata
import glot_frontend/app/public_page_production
import glot_frontend/app/public_page_state
import glot_frontend/app/public_page_view
import glot_frontend/app/runtime
import glot_web/page/seo
import glot_web/page/top_bar
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import youid/uuid.{type Uuid}

pub type Model =
  public_page_state.Model

pub type Msg =
  public_page_message.Msg

pub type Command =
  public_page_command.Command

pub fn init(
  target: route.Route,
  session: runtime.SessionState,
) -> #(Model, Effect(Msg)) {
  let #(model, command) = init_managed(target, session)
  #(model, public_page_production.run(command))
}

pub fn init_managed(
  target: route.Route,
  session: runtime.SessionState,
) -> #(Model, Command) {
  public_page_managed.init(target, session)
}

pub fn session_loaded(model: Model, session: runtime.SessionState) -> Model {
  public_page_managed.session_loaded(model, session)
}

pub fn update(
  model: Model,
  msg: Msg,
  session: runtime.SessionState,
) -> #(Model, Effect(Msg), AppEvent) {
  let #(model, command, event) = update_managed(model, msg, session)
  #(model, public_page_production.run(command), event)
}

pub fn update_managed(
  model: Model,
  msg: Msg,
  session: runtime.SessionState,
) -> #(Model, Command, AppEvent) {
  case public_page_managed.update(model, msg, session) {
    option.Some(transition) -> #(
      transition.model,
      transition.command,
      transition.event,
    )
    option.None -> #(model, public_page_command.None, event.NoAppEvent)
  }
}

pub fn view(
  model: Model,
  session: runtime.SessionState,
  now: Timestamp,
) -> Element(Msg) {
  public_page_view.view(model, session, now)
}

pub fn metadata(model: Model, current_route: route.Route) -> seo.Metadata {
  public_page_metadata.metadata(model, current_route)
}

pub fn quick_actions(
  model: Model,
  current_user_id: option.Option(Uuid),
) -> List(top_bar.Action(Msg)) {
  public_page_actions.actions(model, current_user_id)
}
