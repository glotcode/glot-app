import gleam/int
import gleam/list
import gleam/option
import gleam/time/timestamp
import glot_core/admin/periodic_job_dto
import glot_core/helpers/timestamp_helpers
import glot_core/loadable
import glot_core/route
import glot_frontend/admin/jobs/ui as admin_job_ui
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/ui/table as admin_table
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/periodic_jobs/list_message.{type Msg}
import glot_frontend/admin/periodic_jobs/list_model.{type Model}

pub fn view(model: Model, now: timestamp.Timestamp) -> Element(Msg) {
  admin_layout.page(
    title: "Periodic jobs",
    intro: "Review scheduler definitions, scan health quickly, and open a dedicated detail page when you need to edit one.",
    content: [
      status_banner(model.periodic_jobs),
      summary_view(model),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Definitions"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "This index stays compact on purpose. Open a periodic job to inspect its payload, timestamps, and editable scheduler settings.",
            ),
          ]),
        ]),
        periodic_jobs_content(model, now),
      ]),
    ],
  )
}

fn summary_view(model: Model) -> Element(Msg) {
  let periodic_jobs = case model.periodic_jobs {
    loadable.Loaded(periodic_jobs) -> periodic_jobs
    _ -> []
  }

  let total_count = list.length(periodic_jobs)
  let enabled_count =
    periodic_jobs
    |> list.filter(fn(job) { job.enabled })
    |> list.length
  let disabled_count = total_count - enabled_count
  let failing_count =
    periodic_jobs
    |> list.filter(fn(job) {
      case job.last_enqueue_error {
        option.Some(_) -> True
        option.None -> False
      }
    })
    |> list.length

  html.div([attribute.class("admin-periodic-jobs-page__summary-grid")], [
    admin_layout.summary_card_with_class(
      "admin-page__policy admin-periodic-jobs-page__summary-card",
      "Definitions",
      int.to_string(total_count),
    ),
    admin_layout.summary_card_with_class(
      "admin-page__policy admin-periodic-jobs-page__summary-card",
      "Enabled",
      int.to_string(enabled_count),
    ),
    admin_layout.summary_card_with_class(
      "admin-page__policy admin-periodic-jobs-page__summary-card",
      "Disabled",
      int.to_string(disabled_count),
    ),
    admin_layout.summary_card_with_class(
      "admin-page__policy admin-periodic-jobs-page__summary-card",
      "Errors",
      int.to_string(failing_count),
    ),
  ])
}

fn periodic_jobs_table(
  periodic_jobs: List(periodic_job_dto.PeriodicJobResponse),
  now: timestamp.Timestamp,
) -> Element(Msg) {
  admin_table.table(
    periodic_job_columns(),
    list.map(periodic_jobs, fn(periodic_job) {
      periodic_job_row(periodic_job, now)
    }),
  )
}

fn periodic_job_row(
  periodic_job: periodic_job_dto.PeriodicJobResponse,
  now: timestamp.Timestamp,
) -> Element(Msg) {
  admin_table.row([
    admin_table.cell(job_type_column(), [
      html.span([attribute.class("admin-table__value--primary")], [
        html.text(admin_job_ui.job_type_label(periodic_job.job_type)),
      ]),
    ]),
    admin_table.cell(state_column(), [
      status_chip(periodic_job),
    ]),
    admin_table.cell(cadence_column(), [
      html.text(int.to_string(periodic_job.interval_seconds) <> "s"),
    ]),
    admin_table.cell(next_run_column(), [
      admin_table.primary_value(timestamp_helpers.relative_label(
        periodic_job.next_run_at,
        now,
      )),
    ]),
    admin_table.cell(last_enqueued_column(), [
      admin_table.value(optional_relative_timestamp(
        periodic_job.last_enqueued_at,
        now,
      )),
    ]),
    admin_table.cell(action_column(), [
      admin_layout.secondary_link(
        [web_route.href(route.Admin(route.AdminPeriodicJob(periodic_job.id)))],
        "Open",
      ),
    ]),
  ])
}

fn status_banner(
  state: loadable.Loadable(List(periodic_job_dto.PeriodicJobResponse)),
) -> Element(Msg) {
  admin_status.loadable_status(state, "Loading periodic jobs...")
}

fn periodic_jobs_content(
  model: Model,
  now: timestamp.Timestamp,
) -> Element(Msg) {
  loadable.fold(
    model.periodic_jobs,
    admin_status.empty_state("No periodic jobs were returned."),
    admin_status.empty_state("Loading periodic jobs..."),
    fn(periodic_jobs) {
      case periodic_jobs {
        [] -> admin_status.empty_state("No periodic jobs were returned.")
        _ -> periodic_jobs_table(periodic_jobs, now)
      }
    },
    fn(_) { admin_status.empty_state("No periodic jobs were returned.") },
  )
}

fn periodic_job_columns() -> List(admin_table.Column) {
  [
    job_type_column(),
    state_column(),
    cadence_column(),
    next_run_column(),
    last_enqueued_column(),
    action_column(),
  ]
}

fn job_type_column() -> admin_table.Column {
  admin_table.column("Job type")
}

fn state_column() -> admin_table.Column {
  admin_table.fit_column("State")
}

fn cadence_column() -> admin_table.Column {
  admin_table.fit_column("Cadence")
}

fn next_run_column() -> admin_table.Column {
  admin_table.column("Next run")
}

fn last_enqueued_column() -> admin_table.Column {
  admin_table.column("Last enqueued")
}

fn action_column() -> admin_table.Column {
  admin_table.action_column("Action")
}

fn status_chip(
  periodic_job: periodic_job_dto.PeriodicJobResponse,
) -> Element(Msg) {
  case periodic_job.enabled, periodic_job.last_enqueue_error {
    False, _ -> admin_layout.badge("Disabled", admin_layout.NeutralTone)
    True, option.Some(_) -> admin_layout.badge("Error", admin_layout.DangerTone)
    True, option.None -> admin_layout.badge("Enabled", admin_layout.SuccessTone)
  }
}

fn optional_relative_timestamp(
  value: option.Option(timestamp.Timestamp),
  now: timestamp.Timestamp,
) -> String {
  case value {
    option.Some(timestamp) -> timestamp_helpers.relative_label(timestamp, now)
    option.None -> "Never"
  }
}
