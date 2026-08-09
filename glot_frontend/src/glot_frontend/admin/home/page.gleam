import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/ui/layout as admin_layout
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type Model {
  Model
}

pub type Msg {
  NoOp
}

pub fn init() -> #(Model, admin_effect.Command(Msg)) {
  #(Model, admin_effect.none())
}

pub fn update(model: Model, _msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  #(model, admin_effect.none())
}

pub fn view(_model: Model) -> Element(Msg) {
  admin_layout.page(
    title: "Admin",
    intro: "Administrative configuration, jobs, and logs.",
    content: [
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Analytics"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "Understand product activity, code execution, and service reliability from daily rollups.",
            ),
          ]),
        ]),
        html.div([attribute.class("admin-page__section-grid")], [
          link_card(
            title: "Analytics dashboard",
            description: "Review pageviews, product events, runs, and reliability over configurable date ranges.",
            target: route.Admin(route.AdminAnalytics),
          ),
        ]),
      ]),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Configuration"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "Runtime settings are organized into dedicated pages so more sections can be added cleanly.",
            ),
          ]),
        ]),
        html.div([attribute.class("admin-page__section-grid")], [
          link_card(
            title: "App config",
            description: "Manage docker run settings and future runtime configuration sections.",
            target: route.Admin(route.AdminConfig),
          ),
          link_card(
            title: "Rate limits",
            description: "Review and update API rate limit policies.",
            target: route.Admin(route.AdminRateLimits),
          ),
          link_card(
            title: "Email templates",
            description: "Review stored transactional email templates and edit their subject and body content.",
            target: route.Admin(route.AdminEmailTemplates),
          ),
        ]),
      ]),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Jobs"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "Dedicated admin workflows for scheduling and queue execution.",
            ),
          ]),
        ]),
        html.div([attribute.class("admin-page__section-grid")], [
          link_card(
            title: "Periodic jobs",
            description: "Edit scheduler definitions that drive recurring cleanup and infrastructure jobs.",
            target: route.Admin(route.AdminPeriodicJobs),
          ),
          link_card(
            title: "Jobs",
            description: "Inspect the execution queue and iterate on the admin jobs workflow.",
            target: route.Admin(route.AdminJobs(query: option.None)),
          ),
          link_card(
            title: "Job type policies",
            description: "Set retry, timeout, and backoff defaults that new jobs inherit when they are enqueued.",
            target: route.Admin(route.AdminJobTypePolicies),
          ),
        ]),
      ]),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Users"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "Account administration and user-owned content inspection tools.",
            ),
          ]),
        ]),
        html.div([attribute.class("admin-page__section-grid")], [
          link_card(
            title: "Users",
            description: "List accounts, inspect user state, and edit roles or account access.",
            target: route.Admin(route.AdminUsers(query: option.None)),
          ),
          link_card(
            title: "Snippets",
            description: "Review saved user snippets and inspect their stored files in a read-only admin view.",
            target: route.Admin(route.AdminSnippets(query: option.None)),
          ),
        ]),
      ]),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Logs"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "Review retained API and job logging separately from queue management.",
            ),
          ]),
        ]),
        html.div([attribute.class("admin-page__section-grid")], [
          link_card(
            title: "API logs",
            description: "Review retained API request logging by request ID.",
            target: route.Admin(route.AdminApiLogs(query: option.None)),
          ),
          link_card(
            title: "Run logs",
            description: "Inspect retained execution outcomes with request, session, user, and language filters.",
            target: route.Admin(route.AdminRunLogs(query: option.None)),
          ),
          link_card(
            title: "Job logs",
            description: "Scan operational job log output separately from the primary jobs queue view.",
            target: route.Admin(route.AdminJobLogs(query: option.None)),
          ),
        ]),
      ]),
    ],
  )
}

fn link_card(
  title title: String,
  description description: String,
  target target: route.Route,
) -> Element(Msg) {
  html.article(
    [attribute.class("admin-page__policy admin-page__policy--config")],
    [
      html.div([attribute.class("admin-page__policy-header")], [
        html.div([], [
          html.h3([attribute.class("admin-page__policy-title")], [
            html.text(title),
          ]),
          html.p([attribute.class("admin-page__policy-subtitle")], [
            html.text(description),
          ]),
        ]),
        admin_layout.secondary_link([web_route.href(target)], "Open"),
      ]),
    ],
  )
}

import gleam/option
