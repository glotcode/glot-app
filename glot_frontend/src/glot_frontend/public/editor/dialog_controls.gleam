import glot_core/snippet/snippet_model
import glot_frontend/public/editor/message.{
  type FileMsg, type SettingsMsg, AddEntryKindSelected,
  KeyboardBindingsDraftSelected,
}
import glot_frontend/public/editor/model.{type AddEntryKind}
import glot_frontend/public/editor/settings
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn entry_kind_toggle(
  label: String,
  is_selected: Bool,
  kind: AddEntryKind,
) -> Element(FileMsg) {
  html.button(
    [
      attribute.type_("button"),
      attribute.class(toggle_class(is_selected)),
      attribute.attribute("aria-pressed", bool_attribute(is_selected)),
      event.on_click(AddEntryKindSelected(kind)),
    ],
    [html.text(label)],
  )
}

pub fn keyboard_bindings_option(
  label: String,
  description: String,
  value: settings.KeyboardBindings,
  selected: settings.KeyboardBindings,
) -> Element(SettingsMsg) {
  option_button(
    label,
    description,
    value == selected,
    KeyboardBindingsDraftSelected(value),
  )
}

pub fn visibility_option(
  label: String,
  description: String,
  value: snippet_model.Visibility,
  selected: snippet_model.Visibility,
  on_select: fn(snippet_model.Visibility) -> msg,
) -> Element(msg) {
  option_button(label, description, value == selected, on_select(value))
}

fn option_button(
  label: String,
  description: String,
  is_selected: Bool,
  message: msg,
) -> Element(msg) {
  let class_name = case is_selected {
    True ->
      "editor-page__settings-option editor-page__settings-option--selected"
    False -> "editor-page__settings-option"
  }
  html.button(
    [
      attribute.type_("button"),
      attribute.class(class_name),
      attribute.attribute("aria-pressed", bool_attribute(is_selected)),
      event.on_click(message),
    ],
    [
      html.span([attribute.class("editor-page__settings-option-title")], [
        html.text(label),
      ]),
      html.span([attribute.class("editor-page__settings-option-copy")], [
        html.text(description),
      ]),
    ],
  )
}

fn toggle_class(is_selected: Bool) -> String {
  case is_selected {
    True -> "editor-page__dialog-toggle editor-page__dialog-toggle--selected"
    False -> "editor-page__dialog-toggle"
  }
}

fn bool_attribute(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}
