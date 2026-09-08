import gleam/list
import gleam/string
import wisp

pub type Mode {
  Enforce
  ReportOnly
}

pub type Scope {
  Application
  CarbonAd
}

/// The policy is kept as structured directives so sources can be reviewed and
/// changed independently without editing one opaque header value.
pub fn policy(scope: Scope) -> String {
  let directives = case scope {
    Application -> application_directives()
    CarbonAd -> carbon_ad_directives()
  }

  directives
  |> list.map(serialize_directive)
  |> string.join("; ")
}

pub fn add(response: wisp.Response, mode: Mode, scope: Scope) -> wisp.Response {
  wisp.set_header(response, header_name(mode), policy(scope))
}

fn application_directives() -> List(#(String, List(String))) {
  [
    #("default-src", ["'self'"]),
    #("base-uri", ["'self'"]),
    #("connect-src", ["'self'"]),
    #("font-src", ["'self'"]),
    #("form-action", ["'self'"]),
    #("frame-ancestors", ["'none'"]),
    #("frame-src", ["'self'"]),
    #("img-src", ["'self'", "data:"]),
    #("object-src", ["'none'"]),
    #("script-src", ["'self'"]),
    // Inline SVG artwork and shadow-root components apply
    // runtime styles. Script execution remains restricted independently.
    #("style-src", ["'self'", "'unsafe-inline'"]),
  ]
}

fn carbon_ad_directives() -> List(#(String, List(String))) {
  [
    #("default-src", ["'none'"]),
    #("base-uri", ["'none'"]),
    #("connect-src", ["https://srv.carbonads.net"]),
    #("form-action", ["'none'"]),
    #("frame-ancestors", ["'self'"]),
    #("img-src", ["data:", "https:"]),
    #("object-src", ["'none'"]),
    #("script-src", [
      "https://cdn.carbonads.com",
      "https://cdn4.buysellads.net",
    ]),
    #("style-src", ["'unsafe-inline'"]),
  ]
}

fn header_name(mode: Mode) -> String {
  case mode {
    Enforce -> "Content-Security-Policy"
    ReportOnly -> "Content-Security-Policy-Report-Only"
  }
}

fn serialize_directive(directive: #(String, List(String))) -> String {
  let #(name, sources) = directive
  case sources {
    [] -> name
    _ -> name <> " " <> string.join(sources, " ")
  }
}
