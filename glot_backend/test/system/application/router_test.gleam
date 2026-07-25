import gleam/erlang/process
import gleam/http
import gleam/http/request as http_request
import gleam/http/response as http_response
import gleam/json
import gleam/string
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/system/application/router
import glot_backend/system/http/content_security_policy
import glot_backend/system/lifecycle/server_mode/adapter/worker as server_mode_adapter
import glot_backend/system/lifecycle/server_mode/model as server_mode
import glot_web/page/carbon_ad
import pog
import support/http as http_support
import wisp/simulate

pub fn app_rejects_mismatched_origin_test() {
  let server_mode_subject =
    http_support.start_server_mode(server_mode.Maintenance)
  let request =
    simulate.browser_request(http.Post, "/api/mux")
    |> simulate.json_body(json.object([]))
    |> http_request.set_header("origin", "https://attacker.example")

  let response =
    router.handle_request(
      http_support.test_runtime(
        pog.named_connection(process.new_name("csrf_http_db")),
        dynamic_config.empty(),
      ),
      http_support.test_context(),
      http_support.no_op_log_sink(),
      http_support.no_op_request_tracker(),
      server_mode_adapter.new(server_mode_subject),
      request,
    )

  assert response.status == 400
}

pub fn app_accepts_matching_origin_test() {
  let server_mode_subject =
    http_support.start_server_mode(server_mode.Maintenance)
  let request =
    simulate.browser_request(http.Post, "/api/mux")
    |> simulate.json_body(json.object([]))

  let response =
    router.handle_request(
      http_support.test_runtime(
        pog.named_connection(process.new_name("csrf_http_db")),
        dynamic_config.empty(),
      ),
      http_support.test_context(),
      http_support.no_op_log_sink(),
      http_support.no_op_request_tracker(),
      server_mode_adapter.new(server_mode_subject),
      request,
    )

  assert response.status == 503
  assert http_response.get_header(response, "content-security-policy")
    == Ok(content_security_policy.policy(content_security_policy.Application))
  assert http_response.get_header(
      response,
      "content-security-policy-report-only",
    )
    == Error(Nil)
}

pub fn carbon_ad_document_uses_isolated_policy_test() {
  let server_mode_subject = http_support.start_server_mode(server_mode.Running)
  let request = simulate.browser_request(http.Get, carbon_ad.path)

  let response =
    router.handle_request(
      http_support.test_runtime(
        pog.named_connection(process.new_name("carbon_ad_http_db")),
        dynamic_config.empty(),
      ),
      http_support.test_context(),
      http_support.no_op_log_sink(),
      http_support.no_op_request_tracker(),
      server_mode_adapter.new(server_mode_subject),
      request,
    )

  assert response.status == 200
  assert http_response.get_header(response, "cache-control") == Ok("no-store")
  assert http_response.get_header(response, "content-security-policy")
    == Ok(content_security_policy.policy(content_security_policy.CarbonAd))
  assert http_response.get_header(
      response,
      "content-security-policy-report-only",
    )
    == Error(Nil)
  assert simulate.read_body(response)
    |> string.contains("https://cdn.carbonads.com/carbon.js")
}
