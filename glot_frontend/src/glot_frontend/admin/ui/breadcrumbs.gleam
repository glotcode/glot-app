import gleam/list
import gleam/option
import glot_core/route
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

type Crumb {
  Crumb(label: String, target: option.Option(route.Route))
}

pub fn is_admin_route(current_route: route.Route) -> Bool {
  route.is_admin_route(current_route)
}

pub fn wrap(
  current_route current_route: route.Route,
  content content: Element(msg),
) -> Element(msg) {
  let crumbs = breadcrumbs(current_route)

  case crumbs {
    [] -> content
    _ ->
      html.div([], [
        view(crumbs),
        content,
      ])
  }
}

fn breadcrumbs(current_route: route.Route) -> List(Crumb) {
  case current_route {
    route.Admin(route.AdminHome) -> [current("Admin")]
    route.Admin(route.AdminConfig) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("App config"),
    ]
    route.Admin(route.AdminRateLimits) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Rate limits"),
    ]
    route.Admin(route.AdminJobTypePolicies) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Job type policies"),
    ]
    route.Admin(route.AdminPeriodicJobs) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Periodic jobs"),
    ]
    route.Admin(route.AdminPeriodicJob(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Periodic jobs", route.Admin(route.AdminPeriodicJobs)),
      current("Periodic job detail"),
    ]
    route.Admin(route.AdminUsers(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Users"),
    ]
    route.Admin(route.AdminUser(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Users", route.Admin(route.AdminUsers(query: option.None))),
      current("User detail"),
    ]
    route.Admin(route.AdminJobs(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Jobs"),
    ]
    route.Admin(route.AdminJob(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Jobs", route.Admin(route.AdminJobs(query: option.None))),
      current("Job detail"),
    ]
    route.Admin(route.AdminEmailTemplates) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Email templates"),
    ]
    route.Admin(route.AdminEmailTemplate(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Email templates", route.Admin(route.AdminEmailTemplates)),
      current("Email template detail"),
    ]
    route.Admin(route.AdminSnippets(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      current("Snippets"),
    ]
    route.Admin(route.AdminSnippet(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Snippets", route.Admin(route.AdminSnippets(query: option.None))),
      current("Snippet detail"),
    ]
    route.Admin(route.AdminApiLogs(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Logs", route.Admin(route.AdminHome)),
      current("API logs"),
    ]
    route.Admin(route.AdminApiLog(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Logs", route.Admin(route.AdminHome)),
      link("API logs", route.Admin(route.AdminApiLogs(query: option.None))),
      current("API log detail"),
    ]
    route.Admin(route.AdminRunLogs(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Logs", route.Admin(route.AdminHome)),
      current("Run logs"),
    ]
    route.Admin(route.AdminRunLog(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Logs", route.Admin(route.AdminHome)),
      link("Run logs", route.Admin(route.AdminRunLogs(query: option.None))),
      current("Run log detail"),
    ]
    route.Admin(route.AdminJobLogs(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Logs", route.Admin(route.AdminHome)),
      current("Job logs"),
    ]
    route.Admin(route.AdminJobLog(_)) -> [
      link("Admin", route.Admin(route.AdminHome)),
      link("Logs", route.Admin(route.AdminHome)),
      link("Job logs", route.Admin(route.AdminJobLogs(query: option.None))),
      current("Job log detail"),
    ]
    route.Public(_) | route.Account(_) | route.NotFound(_) -> []
  }
}

fn view(crumbs: List(Crumb)) -> Element(msg) {
  html.div([attribute.class("admin-breadcrumbs-shell")], [
    html.nav(
      [
        attribute.class("admin-breadcrumbs"),
        attribute.attribute("aria-label", "Admin breadcrumbs"),
      ],
      [
        html.ol(
          [attribute.class("admin-breadcrumbs__list")],
          render_crumbs(crumbs) |> list.flatten,
        ),
      ],
    ),
  ])
}

fn render_crumbs(crumbs: List(Crumb)) -> List(List(Element(msg))) {
  case crumbs {
    [] -> []
    [crumb] -> [[render_crumb(crumb)]]
    [crumb, ..rest] -> [
      [render_crumb(crumb), separator()],
      ..render_crumbs(rest)
    ]
  }
}

fn render_crumb(crumb: Crumb) -> Element(msg) {
  let Crumb(label, target) = crumb

  html.li([attribute.class("admin-breadcrumbs__item")], [
    case target {
      option.Some(target) ->
        html.a(
          [attribute.class("admin-breadcrumbs__link"), web_route.href(target)],
          [html.text(label)],
        )
      option.None ->
        html.span(
          [
            attribute.class(
              "admin-breadcrumbs__link admin-breadcrumbs__link--current",
            ),
            attribute.attribute("aria-current", "page"),
          ],
          [html.text(label)],
        )
    },
  ])
}

fn separator() -> Element(msg) {
  html.li(
    [
      attribute.class("admin-breadcrumbs__separator"),
      attribute.attribute("aria-hidden", "true"),
    ],
    [html.text("/")],
  )
}

fn link(label: String, target: route.Route) -> Crumb {
  Crumb(label:, target: option.Some(target))
}

fn current(label: String) -> Crumb {
  Crumb(label:, target: option.None)
}
