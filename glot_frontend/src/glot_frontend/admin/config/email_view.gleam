import glot_frontend/admin/config/section
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/email.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/email_policy.{
  type Field, ContactAddress, DefaultTimeout, FromAddress, FromName, is_empty,
}
import glot_frontend/admin/config/section_view

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  let is_empty = is_empty(model.saved)
  section_view.card(
    title: "Email",
    subtitle: "Stores outbound email settings and the private recipient for privacy requests.",
    state: model.mutation_state,
    dirty:,
    idle_badge: section_view.empty_badge(is_empty),
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "From address",
        "Sender email address used for outbound email.",
        model.draft.from_address,
        FromAddress,
      ),
      input(
        "From name",
        "Optional sender display name.",
        model.draft.from_name,
        FromName,
      ),
      input(
        "Contact address",
        "Optional private recipient for submissions from the public contact form. This value is never returned by the public API.",
        model.draft.contact_address,
        ContactAddress,
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
