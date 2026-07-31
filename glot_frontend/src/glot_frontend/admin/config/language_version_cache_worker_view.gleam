import gleam/option
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/language_version_cache_worker.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/language_version_cache_worker_policy.{
  type Field, DefaultTimeout, RefreshInterval, RefreshStepDelay,
  RefreshStepJitter,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  section_view.card(
    title: "Language version cache worker",
    subtitle: "Controls cache freshness, refresh pacing, and docker-run timeout for language version lookups.",
    state: model.mutation_state,
    dirty:,
    idle_badge: option.None,
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "Refresh interval",
        "Milliseconds before a cached language version is considered stale.",
        model.draft.refresh_interval_ms,
        RefreshInterval,
      ),
      input(
        "Refresh step delay",
        "Base milliseconds between scheduled background refreshes.",
        model.draft.refresh_step_delay_ms,
        RefreshStepDelay,
      ),
      input(
        "Refresh step jitter",
        "Additional random milliseconds added to stagger refreshes. Can be 0.",
        model.draft.refresh_step_jitter_ms,
        RefreshStepJitter,
      ),
      input(
        "Default timeout",
        "Milliseconds to wait for the docker-run version check.",
        model.draft.default_timeout_ms,
        DefaultTimeout,
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
