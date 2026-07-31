import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/docker_run.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/docker_run_policy.{
  type Field, AccessToken, BaseUrl, DefaultTimeout, is_empty,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  let is_empty = is_empty(model.saved)
  section_view.card(
    title: "Docker run",
    subtitle: "Controls the base URL, access token, and fallback timeout used when the backend calls the docker-run service.",
    state: model.mutation_state,
    dirty:,
    idle_badge: section_view.empty_badge(is_empty),
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "Base URL",
        "Example: https://docker-run.internal",
        model.draft.base_url,
        BaseUrl,
      ),
      input(
        "Access token",
        "Stored as a regular app config value.",
        model.draft.access_token,
        AccessToken,
      ),
      input(
        "Default timeout",
        "Fallback timeout in milliseconds when no request deadline is present.",
        model.draft.default_timeout_ms,
        DefaultTimeout,
      ),
    ]),
    footer: section_view.footer(
      load_state: model.load_state,
      mutation_state: model.mutation_state,
      dirty:,
      idle_message: section_view.empty_message(is_empty),
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
