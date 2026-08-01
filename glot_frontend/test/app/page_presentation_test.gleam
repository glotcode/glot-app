import gleeunit
import glot_frontend/app/page_presentation

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn navigation_keeps_the_presented_page_until_the_candidate_is_ready_test() {
  let initial = page_presentation.init(#("home", True))
  let loading_transition =
    page_presentation.begin(initial, #("snippets", False), ready)
  let loading = page_presentation.model(loading_transition)

  assert !page_presentation.did_present(loading_transition)
  assert page_presentation.presented(loading) == #("home", True)
  assert page_presentation.is_transitioning(loading)

  let loaded_transition =
    page_presentation.advance(loading, #("snippets", True), ready)
  let loaded = page_presentation.model(loaded_transition)

  assert page_presentation.did_present(loaded_transition)
  assert page_presentation.presented(loaded) == #("snippets", True)
  assert !page_presentation.is_transitioning(loaded)
}

pub fn immediately_presentable_routes_commit_in_the_navigation_update_test() {
  let initial = page_presentation.init(#("home", True))
  let contact_transition =
    page_presentation.begin(initial, #("contact", True), ready)
  let contact = page_presentation.model(contact_transition)

  assert page_presentation.did_present(contact_transition)
  assert page_presentation.presented(contact) == #("contact", True)
  assert !page_presentation.is_transitioning(contact)
}

pub fn ordinary_page_updates_remain_visible_test() {
  let initial = page_presentation.init(#("counter:0", True))
  let updated_transition =
    page_presentation.advance(initial, #("counter:1", True), ready)
  let updated = page_presentation.model(updated_transition)

  assert !page_presentation.did_present(updated_transition)
  assert page_presentation.presented(updated) == #("counter:1", True)
}

fn ready(page: #(String, Bool)) -> Bool {
  page.1
}
