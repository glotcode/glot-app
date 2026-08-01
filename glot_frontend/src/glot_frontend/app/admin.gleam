import glot_core/route
import glot_frontend/app/admin_root_managed
import glot_frontend/app/admin_root_production
import glot_frontend/app/admin_root_view
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
) -> #(admin_root_managed.Model, Effect(admin_root_managed.Msg)) {
  let initial_route = case spa_navigation.initial_uri() {
    Ok(uri) -> route.from_uri(uri)
    Error(_) -> route.Public(route.Home)
  }
  let #(model, command) =
    admin_root_managed.init(
      initial_route,
      clock.now(),
      page_visibility.document_is_visible(),
    )
  #(model, admin_root_production.run(command))
}

fn update(
  model: admin_root_managed.Model,
  msg: admin_root_managed.Msg,
) -> #(admin_root_managed.Model, Effect(admin_root_managed.Msg)) {
  let #(next_model, command) = admin_root_managed.update(model, msg)
  #(next_model, admin_root_production.run(command))
}

fn view(model: admin_root_managed.Model) -> Element(admin_root_managed.Msg) {
  admin_root_view.view(model)
}
