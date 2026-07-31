import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/cloudflare.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/cloudflare_policy.{
  type Field, AccountId, ApiToken, is_empty,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  let is_empty = is_empty(model.saved)
  section_view.card(
    title: "Cloudflare",
    subtitle: "Stores the Cloudflare account and API token used for outbound email delivery.",
    state: model.mutation_state,
    dirty:,
    idle_badge: section_view.empty_badge(is_empty),
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "Account ID",
        "Cloudflare account identifier.",
        model.draft.account_id,
        AccountId,
      ),
      input(
        "API token",
        "Stored as a regular app config value.",
        model.draft.api_token,
        ApiToken,
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
