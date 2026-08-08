import gleam/option
import gleam/string
import glot_core/route
import glot_web/build_info
import glot_web/page/footer
import lustre/element

const commit = "0123456789abcdef0123456789abcdef01234567"

pub fn valid_commit_test() {
  let assert option.Some(info) = build_info.from_commit(commit)

  assert build_info.short_commit(info) == "0123456"
  assert build_info.commit_url(info)
    == "https://github.com/glotcode/glot-app/commit/" <> commit
}

pub fn invalid_commit_is_hidden_test() {
  assert build_info.from_commit("__GLOT_BUILD_COMMIT__") == option.None
  assert build_info.from_commit("01234567") == option.None
  assert build_info.from_commit("G123456789abcdef0123456789abcdef01234567")
    == option.None
}

pub fn footer_renders_commit_link_test() {
  let assert option.Some(info) = build_info.from_commit(commit)
  let rendered =
    footer.view(
      account_route: route.Account(route.AccountHome),
      build_info: option.Some(info),
    )
    |> element.to_document_string

  assert string.contains(rendered, ">0123456</a>")
  assert !string.contains(rendered, "Version 0123456")
  assert string.contains(rendered, "target=\"_blank\"")
  assert string.contains(rendered, "rel=\"noopener noreferrer\"")
  assert string.contains(
    rendered,
    "https://github.com/glotcode/glot-app/commit/" <> commit,
  )
}

pub fn footer_hides_missing_commit_test() {
  let rendered =
    footer.view(
      account_route: route.Account(route.AccountHome),
      build_info: option.None,
    )
    |> element.to_document_string

  assert !string.contains(rendered, "site-footer__version")
}
