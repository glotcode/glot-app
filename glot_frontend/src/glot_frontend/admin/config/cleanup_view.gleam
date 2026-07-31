import gleam/option
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/cleanup.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/cleanup_policy.{
  type Field, ApiLog, JobLog, Jobs, LoginTokens, PageLog, PageviewLog, RunLog,
  UserActions,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  section_view.card(
    title: "Cleanup",
    subtitle: "Controls retention windows, in days, for scheduled cleanup jobs.",
    state: model.mutation_state,
    dirty:,
    idle_badge: option.None,
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "API log retention",
        "Days to keep API log records.",
        model.draft.api_log_retention_days,
        ApiLog,
      ),
      input(
        "Page log retention",
        "Days to keep page log records.",
        model.draft.page_log_retention_days,
        PageLog,
      ),
      input(
        "Pageview log retention",
        "Days to keep pageview log records.",
        model.draft.pageview_log_retention_days,
        PageviewLog,
      ),
      input(
        "Run log retention",
        "Days to keep run log records.",
        model.draft.run_log_retention_days,
        RunLog,
      ),
      input(
        "Job log retention",
        "Days to keep job log records.",
        model.draft.job_log_retention_days,
        JobLog,
      ),
      input(
        "Jobs retention",
        "Days to keep completed jobs.",
        model.draft.jobs_retention_days,
        Jobs,
      ),
      input(
        "Login token retention",
        "Days to keep used or expired login tokens.",
        model.draft.login_tokens_retention_days,
        LoginTokens,
      ),
      input(
        "User actions retention",
        "Days to keep user action audit records.",
        model.draft.user_actions_retention_days,
        UserActions,
      ),
    ]),
    footer: section_view.footer(
      load_state: model.load_state,
      mutation_state: model.mutation_state,
      dirty:,
      idle_message: option.None,
      reset_msg: ResetClicked,
      save_msg: SaveClicked,
    ),
  )
}

fn input(
  label: String,
  help: String,
  value: String,
  field: Field,
) -> Element(Msg) {
  admin_form.text_input(
    label:,
    help:,
    value:,
    placeholder: "",
    on_input: fn(value) { FieldChanged(field, value) },
  )
}
