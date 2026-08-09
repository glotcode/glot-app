import gleam/int
import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/admin/job_dto
import glot_core/helpers/timestamp_helpers
import glot_core/job/job_model
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/jobs/list_message.{
  type Msg, JobTypeFilterSelected, NextPageClicked, PreviousPageClicked,
  StatusFilterSelected,
}
import glot_frontend/admin/jobs/list_model.{type Model}
import glot_frontend/admin/jobs/ui as admin_job_ui
import glot_frontend/admin/ui/filter as admin_filter
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/pagination as admin_pagination
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/ui/table as admin_table
import glot_frontend/ui/string_helpers
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

type SummaryStat {
  SummaryStat(label: String, value: Int, tone: SummaryTone)
}

type SummaryTone {
  NeutralSummary
  WarningSummary
  DangerSummary
  SuccessSummary
}

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  let items = pagination_model.items(current_page(model))

  admin_layout.page_with_panel_class(
    panel_class: "admin-jobs-page",
    title: "Jobs overview",
    intro: "Review queue health, recent job executions, and filtered slices of the retained jobs history.",
    actions: admin_pagination.cursor_pagination_actions_with_disabled(
      page: current_page(model),
      previous_msg: PreviousPageClicked,
      next_msg: NextPageClicked,
      disabled: loadable.is_loading(model.page),
    ),
    content: [
      html.div([attribute.class("admin-jobs-page__summary-grid")], {
        summary_stats(model.summary)
        |> list.map(summary_card)
      }),
      admin_filter.filter_section(
        copy: filtered_status_text(model, items),
        content: admin_filter.filter_surface(
          [attribute.class("admin-jobs-page__filters")],
          [
            admin_filter.filter_row([], [
              admin_filter.filter_chip_group(
                title: "Status",
                copy: option.None,
                chips: [
                  admin_filter.filter_chip(
                    [event.on_click(StatusFilterSelected(job_dto.AllStatuses))],
                    "All",
                    model.status_filter == job_dto.AllStatuses,
                  ),
                  admin_filter.filter_chip(
                    [
                      event.on_click(StatusFilterSelected(job_dto.PendingStatus)),
                    ],
                    "Pending",
                    model.status_filter == job_dto.PendingStatus,
                  ),
                  admin_filter.filter_chip(
                    [
                      event.on_click(StatusFilterSelected(job_dto.RunningStatus)),
                    ],
                    "Running",
                    model.status_filter == job_dto.RunningStatus,
                  ),
                  admin_filter.filter_chip(
                    [event.on_click(StatusFilterSelected(job_dto.FailedStatus))],
                    "Failed",
                    model.status_filter == job_dto.FailedStatus,
                  ),
                  admin_filter.filter_chip(
                    [event.on_click(StatusFilterSelected(job_dto.DoneStatus))],
                    "Done",
                    model.status_filter == job_dto.DoneStatus,
                  ),
                ],
              ),
              admin_filter.filter_group(
                title: "Job type",
                copy: option.None,
                content: html.select(
                  [
                    attribute.class("admin-page__select admin-page__input"),
                    attribute.value(selected_job_type_value(
                      model.job_type_filter,
                    )),
                    event.on_input(JobTypeFilterSelected),
                  ],
                  job_type_options(selected_job_type_value(
                    model.job_type_filter,
                  )),
                ),
              ),
            ]),
          ],
        ),
      ),
      html.div([attribute.class("admin-page__group")], [
        html.div([attribute.class("admin-page__group-header")], [
          html.h3([attribute.class("admin-page__group-title")], [
            html.text("Queue"),
          ]),
          html.p([attribute.class("admin-page__group-copy")], [
            html.text(
              "Rows are paginated from the backend and use the current filter set, so this view can scale with retained job history.",
            ),
          ]),
        ]),
        admin_status.loadable_status(model.page, "Loading jobs..."),
        jobs_table(model, now),
      ]),
    ],
  )
}

fn jobs_table(model: Model, now: Timestamp) -> Element(Msg) {
  admin_pagination.loadable_cursor_page_content(
    model.page,
    "Loading jobs...",
    "No jobs match the current filters.",
    fn(rows) {
      admin_table.table(job_columns(), {
        rows |> list.map(fn(job) { job_row(job, now) })
      })
    },
  )
}

fn summary_stats(summary: job_dto.JobsSummary) -> List(SummaryStat) {
  [
    SummaryStat("Pending", summary.pending_count, NeutralSummary),
    SummaryStat("Running", summary.running_count, WarningSummary),
    SummaryStat("Failed", summary.failed_count, DangerSummary),
    SummaryStat("Overdue", summary.overdue_count, DangerSummary),
    SummaryStat("Completed", summary.done_count, SuccessSummary),
  ]
}

fn filtered_status_text(
  model: Model,
  items: List(job_dto.JobResponse),
) -> String {
  int.to_string(list.length(items))
  <> " of "
  <> int.to_string(model.summary.total_count)
  <> " jobs shown. "
  <> status_filter_copy(model.status_filter)
  <> " "
  <> job_type_filter_copy(model.job_type_filter)
}

fn summary_card(stat: SummaryStat) -> Element(Msg) {
  html.dl(
    [attribute.class("admin-page__policy admin-jobs-page__summary-card")],
    [
      html.dt([attribute.class("admin-jobs-page__summary-label")], [
        html.text(stat.label),
      ]),
      html.dd([attribute.class("admin-jobs-page__summary-value-row")], [
        html.span([attribute.class("admin-jobs-page__summary-value")], [
          html.text(int.to_string(stat.value)),
        ]),
        html.span([attribute.class(summary_tone_class(stat.tone))], [
          html.text(summary_tone_text(stat.tone)),
        ]),
      ]),
    ],
  )
}

fn job_row(job: job_dto.JobResponse, now: Timestamp) -> Element(Msg) {
  admin_table.row([
    admin_table.cell(job_column(), [
      admin_table.stack([
        html.span([attribute.class("admin-table__value--primary")], [
          html.text(job.job_type),
        ]),
      ]),
    ]),
    admin_table.cell(status_column(), [
      admin_table.stack([
        admin_job_ui.status_badge(job.status, job.overdue),
      ]),
    ]),
    admin_table.cell(schedule_column(), [
      admin_table.stack([
        html.span([attribute.class("admin-table__value--primary")], [
          html.text(timestamp_helpers.relative_label(job.run_at, now)),
        ]),
      ]),
    ]),
    admin_table.cell(attempts_column(), [
      admin_table.stack([
        html.span([attribute.class("admin-table__value--primary")], [
          html.text(
            int.to_string(job.attempts)
            <> " / "
            <> int.to_string(job.max_attempts),
          ),
        ]),
      ]),
    ]),
    admin_table.cell(notes_column(), [admin_table.value(note_text(job))]),
    admin_table.cell(action_column(), [
      admin_layout.secondary_link(
        [web_route.href(route.Admin(route.AdminJob(job.id)))],
        "Open",
      ),
    ]),
  ])
}

fn job_columns() -> List(admin_table.Column) {
  [
    job_column(),
    status_column(),
    schedule_column(),
    attempts_column(),
    notes_column(),
    action_column(),
  ]
}

fn job_column() -> admin_table.Column {
  admin_table.column("Job")
}

fn status_column() -> admin_table.Column {
  admin_table.fit_column("Status")
}

fn schedule_column() -> admin_table.Column {
  admin_table.column("Run at")
}

fn attempts_column() -> admin_table.Column {
  admin_table.fit_column("Attempts")
}

fn notes_column() -> admin_table.Column {
  admin_table.column("Notes")
}

fn action_column() -> admin_table.Column {
  admin_table.action_column("Action")
}

fn note_text(job: job_dto.JobResponse) -> String {
  case job.last_error {
    option.Some(last_error) -> string_helpers.truncate_end(last_error, 50)
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

fn summary_tone_class(tone: SummaryTone) -> String {
  case tone {
    NeutralSummary -> "admin-jobs-page__summary-tone"
    WarningSummary ->
      "admin-jobs-page__summary-tone admin-jobs-page__summary-tone--warning"
    DangerSummary ->
      "admin-jobs-page__summary-tone admin-jobs-page__summary-tone--danger"
    SuccessSummary ->
      "admin-jobs-page__summary-tone admin-jobs-page__summary-tone--success"
  }
}

fn summary_tone_text(tone: SummaryTone) -> String {
  case tone {
    NeutralSummary -> "Queue"
    WarningSummary -> "Active"
    DangerSummary -> "Needs review"
    SuccessSummary -> "Complete"
  }
}

fn status_filter_copy(filter: job_dto.StatusFilter) -> String {
  case filter {
    job_dto.AllStatuses -> "Showing every status."
    job_dto.PendingStatus -> "Focused on jobs waiting to be claimed."
    job_dto.RunningStatus -> "Focused on jobs currently being processed."
    job_dto.FailedStatus -> "Focused on jobs that need operator review."
    job_dto.DoneStatus -> "Focused on completed executions."
  }
}

fn job_type_filter_copy(filter: option.Option(String)) -> String {
  case filter {
    option.None -> "All job types are included."
    option.Some(job_type) -> "Focused on " <> job_type <> "."
  }
}

fn current_page(
  model: Model,
) -> pagination_model.CursorPage(job_dto.JobResponse) {
  case model.page {
    loadable.Loaded(page) -> page
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) ->
      pagination_model.InitialCursorPage(items: [], next_cursor: option.None)
  }
}

fn selected_job_type_value(filter: option.Option(String)) -> String {
  case filter {
    option.Some(job_type) -> job_type
    option.None -> "all"
  }
}

fn job_type_options(selected_value: String) -> List(Element(Msg)) {
  [job_type_option("all", "All jobs", selected_value)]
  |> list.append(
    list.map(job_type_values(), fn(job_type) {
      job_type_option(job_type, job_type, selected_value)
    }),
  )
}

fn job_type_option(
  value: String,
  label: String,
  selected_value: String,
) -> Element(Msg) {
  html.option(
    [
      attribute.value(value),
      attribute.selected(value == selected_value),
    ],
    label,
  )
}

fn job_type_values() -> List(String) {
  [
    job_model.SendEmailJob,
    job_model.DeleteAccountJob,
    job_model.CleanApiLogJob,
    job_model.CleanPageLogJob,
    job_model.CleanPageviewLogJob,
    job_model.CleanRunLogJob,
    job_model.CleanJobLogJob,
    job_model.CleanJobsJob,
    job_model.CleanVerificationTokensJob,
    job_model.CleanUserActionsJob,
    job_model.AggregateMetricsJob,
  ]
  |> list.map(job_model.job_type_to_string)
}
