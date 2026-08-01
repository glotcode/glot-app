import gleeunit
import glot_core/admin_action
import glot_core/public_action
import glot_frontend/api/ownership
import glot_frontend/api/transport

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn route_reads_are_navigation_owned_test() {
  assert ownership.public(public_action.GetSnippetAction)
    == transport.Navigation
  assert ownership.public(public_action.RunAction) == transport.Navigation
  assert ownership.admin(admin_action.GetAdminUsersAction)
    == transport.Navigation
}

pub fn mutations_and_runtime_requests_are_persistent_test() {
  assert ownership.public(public_action.UpdateSnippetAction)
    == transport.Persistent
  assert ownership.public(public_action.GetSessionAction)
    == transport.Persistent
  assert ownership.admin(admin_action.UpdateAdminUserAction)
    == transport.Persistent
}
