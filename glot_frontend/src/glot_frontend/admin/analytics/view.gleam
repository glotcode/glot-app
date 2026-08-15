import gleam/int
import gleam/list
import gleam/option
import glot_core/admin/analytics_dto.{type SpamClassifierOperationalMetrics}
import glot_core/loadable
import glot_frontend/admin/analytics/message.{
  type Msg, DaysSelected, RefreshClicked,
}
import glot_frontend/admin/analytics/model.{type Model}
import glot_frontend/admin/ui/filter as admin_filter
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/ui/table as admin_table
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

const visible_rows = 20

pub fn view(model: Model) -> Element(Msg) {
  admin_layout.page_with_actions(
    title: "Analytics",
    intro: "Product usage and reliability rollups for completed UTC days.",
    actions: [
      admin_layout.secondary_button(
        [attribute.type_("button"), event.on_click(RefreshClicked)],
        "Refresh",
      ),
    ],
    content: [
      range_filter(model),
      load_status(model),
      loadable.fold(
        model.analytics,
        html.div([], []),
        html.div([], []),
        dashboard,
        fn(_) { html.div([], []) },
      ),
    ],
  )
}

fn load_status(model: Model) -> Element(Msg) {
  case model.refresh_error, model.refreshing, model.analytics {
    option.Some(message), _, _ -> admin_status.error_status(message)
    option.None, True, loadable.Loaded(_) -> admin_status.blank_status()
    option.None, _, _ ->
      admin_status.loadable_status(model.analytics, "Loading analytics...")
  }
}

fn range_filter(model: Model) -> Element(Msg) {
  admin_filter.filter_section(
    copy: "The selected range ends at the start of the current UTC day.",
    content: admin_filter.filter_surface([], [
      admin_filter.filter_chip_group(
        title: "Date range",
        copy: option.None,
        chips: list.map([7, 30, 90, 366], fn(days) {
          admin_filter.filter_chip(
            [event.on_click(DaysSelected(days))],
            int.to_string(days)
              <> case days == 1 {
              True -> " day"
              False -> " days"
            },
            model.days == days,
          )
        }),
      ),
    ]),
  )
}

fn dashboard(data: analytics_dto.AnalyticsResponse) -> Element(Msg) {
  let pageviews = sum_pageviews(data.pageviews)
  let events = sum_events(data.product_events)
  let #(successful_runs, failed_runs) = sum_runs(data.runs)
  let #(requests, errors) = sum_reliability(data.reliability)

  html.div([attribute.class("admin-analytics")], [
    html.div([attribute.class(admin_layout.summary_grid_class())], [
      admin_layout.summary_card("Pageviews", format_int(pageviews)),
      admin_layout.summary_card("Product events", format_int(events)),
      admin_layout.summary_card(
        "Code runs",
        format_int(successful_runs + failed_runs),
      ),
      admin_layout.summary_card(
        "Reliability errors",
        format_int(errors) <> " / " <> format_int(requests),
      ),
    ]),
    spam_classifier_metrics(data.spam_classifier, data.reliability),
    completion_notice(data.completed_through),
    metric_group(
      "Pageviews",
      "Latest route and path rollups in the selected range.",
      pageviews_table(data.pageviews),
    ),
    metric_group(
      "Product events",
      "Login and snippet creation activity.",
      events_table(data.product_events),
    ),
    metric_group(
      "Runs by language",
      "Successful and failed code executions.",
      runs_table(data.runs),
    ),
    metric_group(
      "Reliability",
      "Request volume, failures, and average duration by surface.",
      reliability_table(data.reliability),
    ),
  ])
}

fn spam_classifier_metrics(
  metrics: SpamClassifierOperationalMetrics,
  reliability: List(analytics_dto.ReliabilityMetric),
) -> Element(Msg) {
  let history =
    list.filter(reliability, fn(metric) {
      metric.surface == "job" && metric.name == "classify_snippet"
    })
  metric_group(
    "Spam classifier operations",
    "Live backlog, outcomes, attempts, and dedicated queue state, followed by daily worker throughput and reliability.",
    html.div([attribute.class("admin-page__group")], [
      html.div([attribute.class(admin_layout.summary_grid_class())], [
        admin_layout.summary_card("Backlog", format_int(metrics.backlog)),
        admin_layout.summary_card("Classified", format_int(metrics.classified)),
        admin_layout.summary_card("Failed", format_int(metrics.failed)),
        admin_layout.summary_card("Allow", format_int(metrics.allow)),
        admin_layout.summary_card("Review", format_int(metrics.review)),
        admin_layout.summary_card("Block", format_int(metrics.block)),
        admin_layout.summary_card("Attempts", format_int(metrics.attempts)),
        admin_layout.summary_card(
          "Attempted backlog",
          format_int(metrics.attempted_backlog),
        ),
      ]),
      html.div([attribute.class(admin_layout.detail_grid_class())], [
        admin_layout.detail_item(
          "Pending queue jobs",
          format_int(metrics.pending_jobs),
        ),
        admin_layout.detail_item(
          "Running queue jobs",
          format_int(metrics.running_jobs),
        ),
        admin_layout.detail_item(
          "Oldest unclassified update",
          admin_format.optional_timestamp(metrics.oldest_unclassified_at),
        ),
        admin_layout.detail_item(
          "Latest classification",
          admin_format.optional_timestamp(metrics.latest_classified_at),
        ),
        admin_layout.detail_item(
          "Latest terminal failure",
          admin_format.optional_timestamp(metrics.latest_failed_at),
        ),
      ]),
      html.h3([attribute.class("admin-page__group-title")], [
        html.text("Daily classifier jobs"),
      ]),
      classifier_reliability_table(history),
    ]),
  )
}

fn classifier_reliability_table(
  metrics: List(analytics_dto.ReliabilityMetric),
) -> Element(Msg) {
  let day = admin_table.fit_column("Day")
  let jobs = admin_table.fit_column("Jobs")
  let errors = admin_table.fit_column("Errors")
  let duration = admin_table.fit_column("Avg duration")
  data_table(
    [day, jobs, errors, duration],
    metrics
      |> latest
      |> list.map(fn(metric) {
        admin_table.row([
          admin_table.value_cell(day, metric.day),
          admin_table.value_cell(jobs, format_int(metric.request_count)),
          admin_table.value_cell(errors, format_int(metric.error_count)),
          admin_table.value_cell(
            duration,
            duration_label(metric.avg_duration_ns),
          ),
        ])
      }),
  )
}

fn completion_notice(completed_through: option.Option(String)) -> Element(Msg) {
  html.p([attribute.class("admin-page__intro")], [
    html.text(case completed_through {
      option.Some(day) -> "Metrics aggregated through " <> day <> " UTC."
      option.None -> "No completed analytics rollup is available yet."
    }),
  ])
}

fn metric_group(
  title: String,
  copy: String,
  content: Element(Msg),
) -> Element(Msg) {
  html.section([attribute.class("admin-page__group")], [
    html.div([attribute.class("admin-page__group-header")], [
      html.h2([attribute.class("admin-page__group-title")], [html.text(title)]),
      html.p([attribute.class("admin-page__group-copy")], [html.text(copy)]),
    ]),
    content,
  ])
}

fn pageviews_table(
  metrics: List(analytics_dto.PageviewMetric),
) -> Element(Msg) {
  let day = admin_table.fit_column("Day")
  let route = admin_table.column("Route")
  let path = admin_table.column("Path")
  let views = admin_table.fit_column("Views")
  let sessions = admin_table.fit_column("Sessions")
  let users = admin_table.fit_column("Users")
  data_table(
    [day, route, path, views, sessions, users],
    metrics
      |> latest
      |> list.map(fn(metric) {
        admin_table.row([
          admin_table.value_cell(day, metric.day),
          admin_table.primary_cell(route, metric.route),
          admin_table.value_cell(path, metric.path),
          admin_table.value_cell(views, format_int(metric.views)),
          admin_table.value_cell(sessions, format_int(metric.unique_sessions)),
          admin_table.value_cell(users, format_int(metric.unique_users)),
        ])
      }),
  )
}

fn events_table(
  metrics: List(analytics_dto.ProductEventMetric),
) -> Element(Msg) {
  let day = admin_table.fit_column("Day")
  let event_name = admin_table.column("Event")
  let count = admin_table.fit_column("Count")
  let sessions = admin_table.fit_column("Sessions")
  let users = admin_table.fit_column("Users")
  data_table(
    [day, event_name, count, sessions, users],
    metrics
      |> latest
      |> list.map(fn(metric) {
        admin_table.row([
          admin_table.value_cell(day, metric.day),
          admin_table.primary_cell(event_name, metric.event_name),
          admin_table.value_cell(count, format_int(metric.event_count)),
          admin_table.value_cell(sessions, format_int(metric.unique_sessions)),
          admin_table.value_cell(users, format_int(metric.unique_users)),
        ])
      }),
  )
}

fn runs_table(metrics: List(analytics_dto.RunMetric)) -> Element(Msg) {
  let day = admin_table.fit_column("Day")
  let language = admin_table.column("Language")
  let succeeded = admin_table.fit_column("Succeeded")
  let failed = admin_table.fit_column("Failed")
  let sessions = admin_table.fit_column("Sessions")
  let users = admin_table.fit_column("Users")
  data_table(
    [day, language, succeeded, failed, sessions, users],
    metrics
      |> latest
      |> list.map(fn(metric) {
        admin_table.row([
          admin_table.value_cell(day, metric.day),
          admin_table.primary_cell(language, metric.language),
          admin_table.value_cell(succeeded, format_int(metric.successful_runs)),
          admin_table.value_cell(failed, format_int(metric.failed_runs)),
          admin_table.value_cell(sessions, format_int(metric.unique_sessions)),
          admin_table.value_cell(users, format_int(metric.unique_users)),
        ])
      }),
  )
}

fn reliability_table(
  metrics: List(analytics_dto.ReliabilityMetric),
) -> Element(Msg) {
  let day = admin_table.fit_column("Day")
  let surface = admin_table.fit_column("Surface")
  let name = admin_table.column("Name")
  let requests = admin_table.fit_column("Requests")
  let errors = admin_table.fit_column("Errors")
  let duration = admin_table.fit_column("Avg duration")
  data_table(
    [day, surface, name, requests, errors, duration],
    metrics
      |> latest
      |> list.map(fn(metric) {
        admin_table.row([
          admin_table.value_cell(day, metric.day),
          admin_table.value_cell(surface, metric.surface),
          admin_table.primary_cell(name, metric.name),
          admin_table.value_cell(requests, format_int(metric.request_count)),
          admin_table.value_cell(errors, format_int(metric.error_count)),
          admin_table.value_cell(
            duration,
            duration_label(metric.avg_duration_ns),
          ),
        ])
      }),
  )
}

fn data_table(
  columns: List(admin_table.Column),
  rows: List(Element(Msg)),
) -> Element(Msg) {
  case rows {
    [] ->
      html.div([attribute.class("admin-page__empty")], [
        html.text("No data for this range."),
      ])
    _ -> admin_table.table(columns, rows)
  }
}

fn latest(items: List(a)) -> List(a) {
  list.take(items, visible_rows)
}

fn sum_pageviews(metrics: List(analytics_dto.PageviewMetric)) -> Int {
  list.fold(metrics, 0, fn(total, metric) { total + metric.views })
}

fn sum_events(metrics: List(analytics_dto.ProductEventMetric)) -> Int {
  list.fold(metrics, 0, fn(total, metric) { total + metric.event_count })
}

fn sum_runs(metrics: List(analytics_dto.RunMetric)) -> #(Int, Int) {
  list.fold(metrics, #(0, 0), fn(total, metric) {
    #(total.0 + metric.successful_runs, total.1 + metric.failed_runs)
  })
}

fn sum_reliability(
  metrics: List(analytics_dto.ReliabilityMetric),
) -> #(Int, Int) {
  list.fold(metrics, #(0, 0), fn(total, metric) {
    #(total.0 + metric.request_count, total.1 + metric.error_count)
  })
}

fn duration_label(nanoseconds: Int) -> String {
  case nanoseconds < 1_000_000 {
    True -> int.to_string(nanoseconds / 1000) <> " µs"
    False -> int.to_string(nanoseconds / 1_000_000) <> " ms"
  }
}

fn format_int(value: Int) -> String {
  int.to_string(value)
}
