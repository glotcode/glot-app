import gleam/time/timestamp
import glot_core/helpers/timestamp_helpers
import glot_frontend/admin/jobs/ui as admin_job_ui
import glot_frontend/admin/periodic_jobs/message.{
  type Msg, EnabledToggled, IntervalSecondsChanged, NextRunDateChanged,
  NextRunTimeChanged, PayloadChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/periodic_jobs/model.{
  type PeriodicJobEditor, Idle, SaveError, Saved, Saving,
}
import glot_frontend/admin/ui/form as admin_form
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/admin/ui/layout as admin_layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid

pub fn view(
  editor: PeriodicJobEditor,
  now: timestamp.Timestamp,
  recent_jobs: Element(Msg),
) -> Element(Msg) {
  let save_disabled = editor.state == Saving || !is_dirty(editor)

  html.div([attribute.class("admin-job-page__content")], [
    html.div([attribute.class(admin_layout.summary_grid_class())], [
      admin_layout.summary_card_with_class(
        "admin-page__policy admin-periodic-jobs-page__summary-card",
        "Status",
        enabled_text(editor.saved.enabled),
      ),
      admin_layout.summary_card_with_class(
        "admin-page__policy admin-periodic-jobs-page__summary-card",
        "Next run",
        timestamp_helpers.relative_label(editor.metadata.next_run_at, now),
      ),
      admin_layout.summary_card_with_class(
        "admin-page__policy admin-periodic-jobs-page__summary-card",
        "Cadence",
        editor.saved.interval_seconds <> "s",
      ),
    ]),
    html.div([attribute.class("admin-page__group")], [
      html.div([attribute.class("admin-page__group-header")], [
        html.h3([attribute.class("admin-page__group-title")], [
          html.text("Metadata"),
        ]),
        html.p([attribute.class("admin-page__group-copy")], [
          html.text(
            "Operational timestamps and scheduler state for this periodic definition.",
          ),
        ]),
      ]),
      html.div([attribute.class(admin_layout.detail_grid_class())], [
        admin_layout.detail_item("Periodic job ID", uuid.to_string(editor.id)),
        admin_layout.detail_item("Job type", editor.job_type),
        admin_layout.detail_item("Enabled", enabled_text(editor.saved.enabled)),
        admin_layout.detail_item(
          "Next run at",
          admin_format.format_timestamp(editor.metadata.next_run_at),
        ),
        admin_layout.detail_item(
          "Last enqueued at",
          admin_format.optional_timestamp(editor.metadata.last_enqueued_at),
        ),
        admin_layout.detail_item(
          "Created at",
          admin_format.format_timestamp(editor.metadata.created_at),
        ),
        admin_layout.detail_item(
          "Updated at",
          admin_format.format_timestamp(editor.metadata.updated_at),
        ),
        admin_layout.detail_item(
          "Last enqueue error",
          admin_format.optional_text(editor.metadata.last_enqueue_error),
        ),
      ]),
    ]),
    recent_jobs,
    html.div([attribute.class("admin-page__group")], [
      html.div([attribute.class("admin-page__group-header")], [
        html.h3([attribute.class("admin-page__group-title")], [
          html.text("Settings"),
        ]),
        html.p([attribute.class("admin-page__group-copy")], [
          html.text("Edit the scheduler fields stored for this periodic job."),
        ]),
      ]),
      html.div([attribute.class("admin-page__policy")], [
        html.div([attribute.class("admin-page__policy-header")], [
          html.div([], [
            html.h3([attribute.class("admin-page__policy-title")], [
              html.text(admin_job_ui.job_type_label(editor.job_type)),
            ]),
            html.p([attribute.class("admin-page__policy-subtitle")], [
              html.text("Job type is fixed; the fields below are editable."),
            ]),
          ]),
          html.div([attribute.class("admin-page__policy-header-actions")], [
            status_badge(editor),
          ]),
        ]),
        html.div([attribute.class("admin-page__field-grid")], [
          admin_form.text_input_with_attrs(
            label: "Interval seconds",
            help: "Scheduler cadence in seconds. Must be greater than zero.",
            value: editor.draft.interval_seconds,
            input_type: "text",
            placeholder: "",
            field_class: "",
            input_class: "",
            input_attributes: [],
            on_input: IntervalSecondsChanged,
          ),
          admin_form.text_input_with_attrs(
            label: "Next run date",
            help: "Local calendar date for the next enqueue time.",
            value: editor.draft.next_run_date,
            input_type: "date",
            placeholder: "",
            field_class: "",
            input_class: "",
            input_attributes: [],
            on_input: NextRunDateChanged,
          ),
          admin_form.text_input_with_attrs(
            label: "Next run time",
            help: "Local time for the next enqueue time. It is converted back to UTC when saved.",
            value: editor.draft.next_run_time,
            input_type: "time",
            placeholder: "",
            field_class: "",
            input_class: "",
            input_attributes: [attribute.attribute("step", "1")],
            on_input: NextRunTimeChanged,
          ),
          toggle_field(editor),
          admin_form.textarea_input_with_attrs(
            label: "Payload JSON",
            help: "Leave blank for no payload. Saved as raw JSON text without frontend validation.",
            value: editor.draft.payload,
            rows: 6,
            field_class: "admin-periodic-jobs-page__payload-field",
            textarea_class: "admin-periodic-jobs-page__payload-input",
            textarea_attributes: [],
            on_input: PayloadChanged,
          ),
        ]),
        html.div([attribute.class("admin-page__policy-footer")], [
          admin_layout.form_status_block(section_message(editor)),
          admin_layout.form_actions([
            admin_layout.secondary_button(
              [
                attribute.type_("button"),
                attribute.disabled(editor.state == Saving || !is_dirty(editor)),
                event.on_click(ResetClicked),
              ],
              "Reset",
            ),
            html.button(
              [
                attribute.type_("button"),
                attribute.class("admin-page__button"),
                attribute.disabled(save_disabled),
                event.on_click(SaveClicked),
              ],
              [
                html.text(case editor.state {
                  Saving -> "Saving..."
                  _ -> "Save"
                }),
              ],
            ),
          ]),
        ]),
      ]),
    ]),
  ])
}

fn toggle_field(editor: PeriodicJobEditor) -> Element(Msg) {
  html.div([attribute.class("admin-page__field")], [
    html.span([attribute.class("admin-page__field-label")], [
      html.text("Enabled"),
    ]),
    html.button(
      [
        attribute.type_("button"),
        attribute.class(toggle_button_class(editor.draft.enabled)),
        event.on_click(EnabledToggled),
      ],
      [html.text(enabled_text(editor.draft.enabled))],
    ),
    html.span([attribute.class("admin-page__field-help")], [
      html.text(
        "Disabled definitions remain in storage but the scheduler will skip them.",
      ),
    ]),
  ])
}

fn section_message(editor: PeriodicJobEditor) -> Element(Msg) {
  case editor.state {
    SaveError(message) ->
      html.p(
        [
          attribute.class(
            "admin-page__policy-status admin-page__policy-status--error",
          ),
        ],
        [html.text(message)],
      )
    Saving ->
      html.p([attribute.class("admin-page__policy-status")], [
        html.text("Saving changes..."),
      ])
    Saved ->
      html.p([attribute.class("admin-page__policy-status")], [
        html.text("Periodic job saved."),
      ])
    Idle ->
      case is_dirty(editor) {
        True ->
          html.p(
            [
              attribute.class(
                "admin-page__policy-status admin-page__policy-status--dirty",
              ),
            ],
            [html.text("Changes not saved yet.")],
          )
        False ->
          html.p([attribute.class("admin-page__policy-status")], [
            html.text("Scheduler definition is in sync."),
          ])
      }
  }
}

fn status_badge(editor: PeriodicJobEditor) -> Element(Msg) {
  case editor.state, is_dirty(editor) {
    Idle, False -> html.div([], [])
    _, _ ->
      html.span([attribute.class(status_badge_class(editor))], [
        html.text(status_badge_text(editor)),
      ])
  }
}

fn status_badge_text(editor: PeriodicJobEditor) -> String {
  case editor.state {
    SaveError(_) -> "Error"
    Saving -> "Saving"
    Saved -> "Saved"
    Idle ->
      case is_dirty(editor) {
        True -> "Unsaved"
        False -> ""
      }
  }
}

fn status_badge_class(editor: PeriodicJobEditor) -> String {
  case editor.state {
    SaveError(_) -> "admin-page__version admin-page__version--error"
    Saving | Saved -> "admin-page__version admin-page__version--success"
    Idle ->
      case is_dirty(editor) {
        True -> "admin-page__version admin-page__version--dirty"
        False -> "admin-page__version"
      }
  }
}

fn is_dirty(editor: PeriodicJobEditor) -> Bool {
  editor.saved != editor.draft
}

fn enabled_text(value: Bool) -> String {
  case value {
    True -> "Enabled"
    False -> "Disabled"
  }
}

fn toggle_button_class(enabled: Bool) -> String {
  case enabled {
    True -> admin_layout.primary_button_class()
    False -> admin_layout.secondary_button_class()
  }
}
