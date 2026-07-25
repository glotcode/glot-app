import exception
import gleam/json
import glot_backend/system/http/content_security_policy
import glot_backend/system/http/response as response_helpers
import glot_backend/system/lifecycle/request_tracker/ports/request_tracker.{
  type RequestTracker,
}
import glot_backend/system/lifecycle/server_mode/model
import glot_backend/system/lifecycle/server_mode/ports/controller.{
  type Controller,
}
import glot_backend/system/request/context
import wisp

pub fn apply(
  req: wisp.Request,
  ctx: context.Context,
  request_tracker: RequestTracker,
  server_mode: Controller,
  next: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- with_content_security_policy(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.csrf_known_header_protection(req)
  use req <- wisp.handle_head(req)

  case server_mode.current() {
    model.Maintenance -> maintenance_response()
    model.ShuttingDown -> maintenance_response()
    model.Running -> {
      use <- with_tracked_request(request_tracker)
      use <- wisp.serve_static(
        req,
        under: "/static",
        from: ctx.config.static_base_path,
      )

      next(req)
    }
  }
}

fn with_content_security_policy(
  req: wisp.Request,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  let scope = case wisp.path_segments(req) {
    ["ads", "carbon"] -> content_security_policy.CarbonAd
    _ -> content_security_policy.Application
  }

  next()
  |> content_security_policy.add(content_security_policy.Enforce, scope)
}

fn with_tracked_request(
  request_tracker: RequestTracker,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  request_tracker.started()
  use <- exception.defer(fn() { request_tracker.finished() })
  next()
}

fn maintenance_response() -> wisp.Response {
  wisp.json_response(
    json.to_string(response_helpers.error_body(
      "Service temporarily unavailable",
    )),
    503,
  )
}
