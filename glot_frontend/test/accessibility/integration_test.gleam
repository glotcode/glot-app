import gleam/list
import gleam/option
import gleam/time/timestamp
import glot_frontend/account/snippets/page as snippets_page
import glot_frontend/admin/rate_limits/managed as rate_limits_managed
import glot_frontend/admin/rate_limits/view as rate_limits_view
import glot_frontend/public/login/page as login_page
import lustre/element
import support/accessibility

pub fn representative_feature_views_satisfy_the_markup_contract_test() {
  let #(login, _) = login_page.init_managed()
  let #(snippets, _) =
    snippets_page.init_managed(after: option.None, before: option.None)
  let #(rate_limits, _) = rate_limits_managed.init()

  [
    login_page.view(login) |> element.to_document_string,
    snippets_page.view(snippets, timestamp.from_unix_seconds(0))
      |> element.to_document_string,
    rate_limits_view.view(rate_limits) |> element.to_document_string,
  ]
  |> list.each(fn(document) {
    assert accessibility.audit_fragment(document) == []
  })
}

pub fn contract_reports_unsafe_controls_and_broken_relationships_test() {
  let violations =
    accessibility.audit_fragment(
      "<button aria-controls=\"missing\">Open</button><dialog></dialog>",
    )

  assert violations
    == [
      accessibility.ButtonMissingType,
      accessibility.DialogMissingAccessibleName,
      accessibility.BrokenAriaReference("aria-controls", "missing"),
    ]
}
