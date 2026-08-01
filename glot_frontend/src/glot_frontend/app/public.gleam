import glot_core/route
import glot_frontend/app/public_root_managed
import glot_frontend/app/public_root_production
import glot_frontend/app/public_root_view
import glot_frontend/platform/clock
import glot_frontend/platform/page_visibility
import glot_frontend/platform/spa_navigation
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Flags)
  Nil
}

type Flags {
  Flags
}

fn init(
  _flags: Flags,
) -> #(public_root_managed.Model, Effect(public_root_managed.Msg)) {
  let initial_route = case spa_navigation.initial_uri() {
    Ok(uri) -> route.from_uri(uri)
    Error(_) -> route.Public(route.Home)
  }
  let #(model, command) =
    public_root_managed.init(
      initial_route,
      clock.now(),
      page_visibility.document_is_visible(),
    )
  #(model, public_root_production.run(command, model))
}

fn update(
  model: public_root_managed.Model,
  msg: public_root_managed.Msg,
) -> #(public_root_managed.Model, Effect(public_root_managed.Msg)) {
  let #(next_model, command) = public_root_managed.update(model, msg)
  #(next_model, public_root_production.run(command, next_model))
}

fn view(model: public_root_managed.Model) -> Element(public_root_managed.Msg) {
  public_root_view.view(model)
}
