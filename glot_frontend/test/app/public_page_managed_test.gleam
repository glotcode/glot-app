import gleeunit
import glot_core/route
import glot_frontend/app/public_page_managed
import glot_frontend/app/public_page_state
import glot_frontend/app/runtime

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn routes_owned_by_the_other_application_initialize_empty_test() {
  let #(model, _) =
    public_page_managed.init(
      route.Admin(route.AdminHome),
      runtime.LoadingSession,
    )

  assert model == public_page_state.Empty
}
