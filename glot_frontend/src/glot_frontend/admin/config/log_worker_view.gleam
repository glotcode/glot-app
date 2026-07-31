import gleam/option
import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/log_worker.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/log_worker_policy.{
  type Field, FlushInterval, MaxBatchSize, MaxBufferSize,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  section_view.card(
    title: "Log worker",
    subtitle: "Controls batching and buffering for API, page, and pageview log writes.",
    state: model.mutation_state,
    dirty:,
    idle_badge: option.None,
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "Flush interval",
        "Milliseconds to wait before flushing a partial log batch.",
        model.draft.flush_interval_ms,
        FlushInterval,
      ),
      input(
        "Max batch size",
        "Flush immediately once this many pending entries are buffered.",
        model.draft.max_batch_size,
        MaxBatchSize,
      ),
      input(
        "Max buffer size",
        "Cap on queued log entries before the oldest pending entries are dropped.",
        model.draft.max_buffer_size,
        MaxBufferSize,
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
