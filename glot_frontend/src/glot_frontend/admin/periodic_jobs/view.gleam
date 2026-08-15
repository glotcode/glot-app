import gleam/int
import gleam/list
import gleam/option
import gleam/time/timestamp
import glot_core/admin/job_dto
import glot_core/helpers/timestamp_helpers
import glot_core/route
import glot_frontend/admin/jobs/ui as admin_job_ui
import glot_frontend/admin/periodic_jobs/message.{type Msg}
import glot_frontend/admin/periodic_jobs/model.{
  type Model, type Status, LoadError, Loading, NotLoaded, Ready,
}
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/ui/table as admin_table
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/periodic_jobs/editor_view

pub fn view(model: Model, now: timestamp.Timestamp) -> Element(Msg) {
  admin_layout.page(
    title: "Periodic job detail",
    intro: "Inspect one scheduler definition and update cadence, enabled state, next enqueue time, or payload.",
    content: [status_banner(model.status), detail_view(model, now)],
  )
}

fn detail_view(model: Model, now: timestamp.Timestamp) -> Element(Msg) {
  case model.periodic_job, model.status {
    option.None, Loading ->
      html.div([attribute.class("admin-page__empty")], [
        html.text("Loading periodic job..."),
      ])
    option.None, _ ->
      html.div([attribute.class("admin-page__empty")], [
        html.text("This periodic job could not be loaded."),
      ])
    option.Some(editor), _ ->
      editor_view.view(editor, now, recent_jobs_group(model, now))
  }
}

fn recent_jobs_group(model: Model, now: timestamp.Timestamp) -> Element(Msg) {
  let count_text =
    int.to_string(list.length(model.recent_jobs))
    <> " recent jobs shown for this periodic definition."

  html.div([attribute.class("admin-page__group")], [
    html.div([attribute.class("admin-page__group-header")], [
      html.h3([attribute.class("admin-page__group-title")], [
        html.text("Recent jobs"),
      ]),
      html.p([attribute.class("admin-page__group-copy")], [
        html.text(count_text),
      ]),
    ]),
    recent_jobs_status_view(model.jobs_status),
    recent_jobs_table(model.recent_jobs, model.jobs_status, now),
  ])
}

fn recent_jobs_status_view(status: Status) -> Element(Msg) {
  case status {
    NotLoaded | Ready -> admin_status.blank_status()
    Loading -> admin_status.status("Loading recent jobs...")
    LoadError(message) -> admin_status.error_status(message)
  }
}

fn recent_jobs_table(
  recent_jobs: List(job_dto.JobResponse),
  status: Status,
  now: timestamp.Timestamp,
) -> Element(Msg) {
  case recent_jobs, status {
    [], Loading -> admin_status.empty_state("Loading recent jobs...")
    [], _ ->
      admin_status.empty_state(
        "No jobs were found for this periodic definition.",
      )
    _, _ ->
      admin_table.table(recent_job_columns(), {
        recent_jobs |> list.map(fn(job) { recent_job_row(job, now) })
      })
  }
}

fn recent_job_row(
  job: job_dto.JobResponse,
  now: timestamp.Timestamp,
) -> Element(Msg) {
  admin_table.row([
    admin_table.cell(job_column(), [
      html.span([attribute.class("admin-table__value--primary")], [
        html.text(admin_job_ui.job_type_label(job.job_type)),
      ]),
    ]),
    admin_table.cell(status_column(), [
      admin_job_ui.status_badge(job.status, job.overdue),
    ]),
    admin_table.cell(schedule_column(), [
      html.span([attribute.class("admin-table__value--primary")], [
        html.text(timestamp_helpers.relative_label(job.run_at, now)),
      ]),
    ]),
    admin_table.cell(attempts_column(), [
      html.span([attribute.class("admin-table__value--primary")], [
        html.text(
          int.to_string(job.attempts)
          <> " / "
          <> int.to_string(job.max_attempts),
        ),
      ]),
    ]),
    admin_table.cell(open_column(), [
      admin_layout.secondary_link(
        [web_route.href(route.Admin(route.AdminJob(job.id)))],
        "Open",
      ),
    ]),
  ])
}

fn recent_job_columns() -> List(admin_table.Column) {
  [
    job_column(),
    status_column(),
    schedule_column(),
    attempts_column(),
    open_column(),
  ]
}

fn job_column() -> admin_table.Column {
  admin_table.column("Job")
}

fn status_column() -> admin_table.Column {
  admin_table.fit_column("Status")
}

fn schedule_column() -> admin_table.Column {
  admin_table.column("Schedule")
}

fn attempts_column() -> admin_table.Column {
  admin_table.fit_column("Attempts")
}

fn open_column() -> admin_table.Column {
  admin_table.action_column("Open")
}

fn status_banner(status: Status) -> Element(Msg) {
  case status {
    NotLoaded | Ready -> html.div([], [])
    Loading -> admin_status.status("Loading periodic job...")
    LoadError(message) -> admin_status.error_status(message)
  }
}
