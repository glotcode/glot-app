import gleam/int
import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/admin/job_dto
import glot_core/admin/job_log_dto
import glot_core/helpers/timestamp_helpers
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/jobs/message.{
  type Msg, NextLogsPageClicked, OpenCreateJobClicked, PreviousLogsPageClicked,
}
import glot_frontend/admin/jobs/model.{
  type Model, LoadError, Loading, NotLoaded, Ready,
}
import glot_frontend/admin/jobs/ui as admin_job_ui
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/pagination as admin_pagination
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/ui/table as admin_table
import glot_frontend/ui/duration_label
import glot_frontend/ui/string_helpers
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid

import glot_frontend/admin/jobs/create_job_dialog_view

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  html.div([], [
    admin_layout.page_with_panel_class(
      panel_class: "admin-job-page",
      title: "Job detail",
      intro: "Inspect one job execution, its scheduling metadata, and any stored payload or error output.",
      actions: [
        html.button(
          [
            attribute.class("admin-page__button"),
            attribute.type_("button"),
            attribute.disabled(option.is_none(model.job)),
            event.on_click(OpenCreateJobClicked),
          ],
          [html.text("Start new job")],
        ),
      ],
      content: [job_status_view(model), detail_view(model, now)],
    ),
    create_job_dialog_view.view(model),
  ])
}

fn job_status_view(model: Model) -> Element(Msg) {
  case model.job_status {
    NotLoaded | Ready -> admin_status.status("")
    Loading -> admin_status.status("Loading job...")
    LoadError(message) -> admin_status.error_status(message)
  }
}

fn detail_view(model: Model, now: Timestamp) -> Element(Msg) {
  case model.job, model.job_status {
    option.None, Loading -> admin_status.empty_state("Loading job...")
    option.None, _ -> admin_status.empty_state("This job could not be loaded.")
    option.Some(job), _ ->
      html.div([attribute.class("admin-job-page__content")], [
        html.div([attribute.class(admin_layout.summary_grid_class())], [
          admin_layout.summary_card(
            "Status",
            admin_job_ui.status_text(job.status, job.overdue),
          ),
          admin_layout.summary_card(
            "Run at",
            timestamp_helpers.relative_label(job.run_at, now),
          ),
          admin_layout.summary_card(
            "Attempts",
            int.to_string(job.attempts)
              <> " / "
              <> int.to_string(job.max_attempts),
          ),
        ]),
        admin_layout.section(
          title: "Metadata",
          copy: "Identifiers and timestamps captured for this execution.",
          content: html.div(
            [attribute.class(admin_layout.detail_grid_class())],
            [
              admin_layout.detail_item("Job ID", uuid.to_string(job.id)),
              admin_layout.detail_item(
                "Request ID",
                admin_format.optional_uuid(job.request_id),
              ),
              periodic_job_detail_item(job.periodic_job_id),
              admin_layout.detail_item("Job type", job.job_type),
              admin_layout.detail_item("Queue", job.queue_name),
              admin_layout.detail_item(
                "Dedupe key",
                option.unwrap(job.dedupe_key, "—"),
              ),
              admin_layout.detail_item(
                "Status",
                admin_job_ui.status_text(job.status, job.overdue),
              ),
              admin_layout.detail_item("Overdue", bool_text(job.overdue)),
              admin_layout.detail_item(
                "Run at",
                admin_format.format_timestamp(job.run_at),
              ),
              admin_layout.detail_item(
                "Started at",
                admin_format.optional_timestamp(job.started_at),
              ),
              admin_layout.detail_item(
                "Completed at",
                admin_format.optional_timestamp(job.completed_at),
              ),
              admin_layout.detail_item(
                "Created at",
                admin_format.format_timestamp(job.created_at),
              ),
              admin_layout.detail_item(
                "Updated at",
                admin_format.format_timestamp(job.updated_at),
              ),
            ],
          ),
        ),
        job_logs_group(model, now),
        admin_layout.section(
          title: "Notes",
          copy: "Current operator-facing interpretation of this job state.",
          content: html.div([attribute.class("admin-page__policy")], [
            html.p([attribute.class("admin-job-page__body-text")], [
              html.text(note_text(job)),
            ]),
          ]),
        ),
        admin_layout.section(
          title: "Payload",
          copy: "Stored raw payload string for this job, if any.",
          content: code_block(admin_format.optional_text(job.payload)),
        ),
        admin_layout.section(
          title: "Last error",
          copy: "Latest persisted failure message, if one was recorded.",
          content: code_block(admin_format.optional_text(job.last_error)),
        ),
      ])
  }
}

fn job_logs_group(model: Model, now: Timestamp) -> Element(Msg) {
  let rows = pagination_model.items(model.logs_page)
  let count_text =
    int.to_string(list.length(rows)) <> " log entries shown for this job."

  html.div([attribute.class("admin-page__group")], [
    html.div([attribute.class("admin-page__group-header")], [
      html.div([], [
        html.h3([attribute.class("admin-page__group-title")], [
          html.text("Logs"),
        ]),
        html.p([attribute.class("admin-page__group-copy")], [
          html.text(count_text),
        ]),
      ]),
      html.div(
        [attribute.class("admin-page__actions")],
        admin_pagination.cursor_pagination_actions(
          model.logs_page,
          PreviousLogsPageClicked,
          NextLogsPageClicked,
        ),
      ),
    ]),
    logs_status_view(model),
    job_logs_table(model, now),
  ])
}

fn logs_status_view(model: Model) -> Element(Msg) {
  case model.logs_status {
    NotLoaded | Ready -> admin_status.status("")
    Loading -> admin_status.status("Loading job logs...")
    LoadError(message) -> admin_status.error_status(message)
  }
}

fn job_logs_table(model: Model, now: Timestamp) -> Element(Msg) {
  let rows = pagination_model.items(model.logs_page)

  case rows, model.logs_status {
    [], Loading -> admin_status.empty_state("Loading job logs...")
    [], _ -> admin_status.empty_state("No job logs were found for this job.")

    _, _ ->
      admin_table.table(job_log_columns(), {
        rows |> list.map(fn(log) { job_log_row(log, now) })
      })
  }
}

fn job_log_row(
  log: job_log_dto.JobLogResponse,
  now: Timestamp,
) -> Element(Msg) {
  admin_table.row([
    admin_table.linked_primary_cell(
      log_id_column(),
      [web_route.href(route.Admin(route.AdminJobLog(log.id)))],
      string_helpers.truncate_stem_middle(uuid.to_string(log.id), 18),
      option.None,
    ),
    admin_table.primary_cell(
      when_column(),
      timestamp_helpers.relative_label(log.created_at, now),
    ),
    admin_table.value_cell(attempt_column(), int.to_string(log.attempt)),
    admin_table.value_cell(
      duration_column(),
      duration_label.duration_in_ms_label(log.duration_ns),
    ),
    admin_table.cell(error_column(), [admin_status.error_badge(log.has_error)]),
    admin_table.open_link_cell([
      web_route.href(route.Admin(route.AdminJobLog(log.id))),
    ]),
  ])
}

fn job_log_columns() -> List(admin_table.Column) {
  [
    log_id_column(),
    when_column(),
    attempt_column(),
    duration_column(),
    error_column(),
    open_column(),
  ]
}

fn log_id_column() -> admin_table.Column {
  admin_table.column("Log ID")
}

fn when_column() -> admin_table.Column {
  admin_table.column("When")
}

fn attempt_column() -> admin_table.Column {
  admin_table.fit_column("Attempt")
}

fn duration_column() -> admin_table.Column {
  admin_table.fit_column("Duration")
}

fn error_column() -> admin_table.Column {
  admin_table.fit_column("Error")
}

fn open_column() -> admin_table.Column {
  admin_table.open_column()
}

fn linked_detail_item(
  label: String,
  value: String,
  destination: route.Route,
) -> Element(Msg) {
  admin_layout.detail_link_item(label, value, [web_route.href(destination)])
}

fn periodic_job_detail_item(value: option.Option(uuid.Uuid)) -> Element(Msg) {
  case value {
    option.Some(id) ->
      linked_detail_item(
        "Periodic job ID",
        uuid.to_string(id),
        route.Admin(route.AdminPeriodicJob(id)),
      )
    option.None -> admin_layout.detail_item("Periodic job ID", "None")
  }
}

fn code_block(value: String) -> Element(Msg) {
  admin_layout.code_block(value)
}

fn bool_text(value: Bool) -> String {
  case value {
    True -> "Yes"
    False -> "No"
  }
}

fn note_text(job: job_dto.JobDetailResponse) -> String {
  case job.last_error {
    option.Some(last_error) -> last_error
    option.None ->
      case job.status {
        "pending" ->
          case job.overdue {
            True -> "Queued past its scheduled run time."
            False -> "Queued"
          }
        "running" -> "Currently being processed."
        "failed" -> "Failed without a stored error message."
        "done" -> "Completed successfully."
        _ -> ""
      }
  }
}
