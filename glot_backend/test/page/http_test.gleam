import gleam/erlang/process
import gleam/http
import gleam/http/request as http_request
import gleam/http/response as http_response
import gleam/option
import gleam/string
import glot_backend/page
import glot_backend/request_policy/model/config as request_policy_config
import glot_backend/static_assets
import glot_core/availability_mode
import pog
import support/http as http_support
import wisp/simulate

pub fn page_returns_503_with_retry_after_in_maintenance_mode_test() {
  let assert Ok(_) = http_support.write_test_manifest()
  let availability =
    request_policy_config.AvailabilityConfig(
      mode: availability_mode.MaintenanceMode,
      message: "Scheduled platform maintenance.",
      retry_after_seconds: option.Some(600),
    )
  let db = pog.named_connection(process.new_name("availability_http_db"))
  let request =
    simulate.request(http.Get, "/snippets")
    |> http_request.set_cookie("glot_theme", "dark")

  let response =
    page.handle_request(
      http_support.test_runtime(
        db,
        http_support.test_dynamic_config(availability),
      ),
      http_support.test_context(),
      http_support.no_op_log_sink(),
      request,
    )

  assert response.status == 503
  assert http_response.get_header(response, "retry-after") == Ok("600")

  let body = simulate.read_body(response)
  assert string.contains(body, "maintenance-page__shell")
  assert string.contains(body, "data-theme=\"dark\"")
  assert string.contains(body, "/static/glot_frontend.js") == False
  assert string.contains(body, "/static/assets/test-styles.css")
  assert string.contains(body, "Temporarily unavailable")
  assert string.contains(body, "Scheduled platform maintenance.")
  assert string.contains(body, "Please try again in about 10 minute(s).")
}

pub fn public_page_uses_public_frontend_entry_test() {
  let body = http_support.page_body("/login")

  assert string.contains(body, "content=\"light dark\" name=\"color-scheme\"")
  assert string.contains(body, "localStorage") == False
  assert string.contains(body, "data-theme=") == False
  assert string.contains(body, "/static/assets/test-frontend.js")
  assert string.contains(body, "/static/assets/test-admin.js") == False
  assert string.contains(body, "/static/assets/test-shared.js")
  assert string.contains(body, "/static/assets/test-styles.css")
  assert string.contains(body, "/static/assets/test-admin.css") == False
}

pub fn editor_page_delivers_ssr_state_as_a_csp_compatible_data_block_test() {
  let body = http_support.page_body("/new/javascript")

  assert string.contains(body, "<div id=\"app\"")
  assert string.contains(body, "id=\"glot-ssr-data\"")
  assert string.contains(body, "type=\"application/json\"")
  assert string.contains(body, "\"kind\":\"new\"")
  assert string.contains(body, "data-ssr=") == False
}

pub fn public_pages_render_complete_search_metadata_test() {
  let home = http_support.page_body("/")
  let login = http_support.page_body("/login")

  assert string.contains(
    home,
    "<title>Online Code Playground – Run &amp; Share Code | glot.io</title>",
  )
  assert string.contains(home, "href=\"https://glot.io/\" rel=\"canonical\"")
  assert string.contains(home, "property=\"og:title\"")
  assert string.contains(home, "name=\"twitter:card\"")
  assert string.contains(home, "application/ld+json")
  assert string.contains(home, "WebApplication")
  assert string.contains(home, "/static/assets/test-home-banner.jpg")
  assert string.contains(home, "<h1")

  assert string.contains(login, "content=\"noindex, nofollow\" name=\"robots\"")
  assert string.contains(
    login,
    "href=\"https://glot.io/login\" rel=\"canonical\"",
  )
}

pub fn private_pages_are_not_indexable_test() {
  let account = http_support.page_body("/account")
  let admin = http_support.page_body("/admin")

  assert string.contains(
    account,
    "content=\"noindex, nofollow\" name=\"robots\"",
  )
  assert string.contains(admin, "content=\"noindex, nofollow\" name=\"robots\"")
}

pub fn page_renders_valid_theme_cookie_test() {
  let light_body = http_support.page_body_with_theme("/login", "light")
  let dark_body = http_support.page_body_with_theme("/login", "dark")

  assert string.contains(light_body, "data-theme=\"light\"")
  assert string.contains(dark_body, "data-theme=\"dark\"")
}

pub fn page_ignores_invalid_theme_cookie_test() {
  let body = http_support.page_body_with_theme("/login", "sepia")

  assert string.contains(body, "data-theme=") == False
}

pub fn admin_page_uses_admin_frontend_entry_test() {
  let body = http_support.page_body("/admin")

  assert string.contains(body, "/static/assets/test-admin.js")
  assert string.contains(body, "/static/assets/test-frontend.js") == False
  assert string.contains(body, "/static/assets/test-shared.js")
  assert string.contains(body, "/static/assets/test-styles.css")
  assert string.contains(body, "/static/assets/test-admin.css")
}

pub fn static_assets_resolve_entries_from_the_manifest_test() {
  let assert Ok(_) = http_support.write_test_manifest()
  let assert Ok(assets) =
    static_assets.load(http_support.test_static_base_path())

  assert assets.frontend_src == "/static/assets/test-frontend.js"
  assert assets.frontend_preloads == ["/static/assets/test-shared.js"]
  assert assets.social_image_href == "/static/assets/test-home-banner.jpg"
}
