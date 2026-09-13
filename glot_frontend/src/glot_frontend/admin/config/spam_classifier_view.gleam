import glot_core/snippet/classifier_provider
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_view
import glot_frontend/admin/config/spam_classifier.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/spam_classifier_policy.{
  type Field, AuthToken, BaseUrl, Provider, is_empty,
}
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  let empty = is_empty(model.saved)
  section_view.card(
    title: "Spam classifier",
    subtitle: "Classification is advisory. Results never block saving, running or viewing snippets, and do not change visibility.",
    state: model.mutation_state,
    dirty: dirty,
    idle_badge: section_view.empty_badge(empty),
    fields: html.div([attribute.class("admin-page__field-grid")], [
      admin_form.select_input(
        label: "Provider",
        value: classifier_provider.to_string(model.draft.provider),
        on_input: fn(value) { FieldChanged(Provider, value) },
        options: [
          #("external", "External service"),
          #("local", "Local rules and similarity"),
        ],
        help: "Applies to subsequent attempts and manual reclassification.",
      ),
      input(
        "Base URL",
        "Required only for external mode. Example: http://classifier.internal:8081",
        model.draft.base_url,
        BaseUrl,
      ),
      input(
        "Auth token",
        "Required only for external mode. Retained when switching to local.",
        model.draft.auth_token,
        AuthToken,
      ),
    ]),
    footer: section_view.footer(
      load_state: model.load_state,
      mutation_state: model.mutation_state,
      dirty: dirty,
      idle_message: section_view.empty_message(empty),
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
