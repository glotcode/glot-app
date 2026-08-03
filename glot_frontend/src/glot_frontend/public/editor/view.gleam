import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_frontend/public/editor/console_view
import glot_frontend/public/editor/document
import glot_frontend/public/editor/file_dialog_view
import glot_frontend/public/editor/ids
import glot_frontend/public/editor/lifecycle_view
import glot_frontend/public/editor/message.{
  type EditorMsg, type Msg, EditMetadataClicked, Editor as EditorMessage,
  Execution, File, Metadata, RestoreDraft, RunCancellationSubmitted,
  RunSubmitted, Save, SaveClicked, Settings, SnippetInfo, SnippetInfoClicked,
  SourceCodeChanged,
}
import glot_frontend/public/editor/metadata_dialog_view
import glot_frontend/public/editor/model.{
  type Editor, type Model, Lifecycle, Ready,
}
import glot_frontend/public/editor/operations
import glot_frontend/public/editor/policy
import glot_frontend/public/editor/restore_draft_view
import glot_frontend/public/editor/save_dialog_view
import glot_frontend/public/editor/settings as editor_settings
import glot_frontend/public/editor/settings_dialog_view
import glot_frontend/public/editor/snippet_info_view
import glot_frontend/public/editor/tab_semantics
import glot_frontend/public/editor/workspace_toolbar_view
import glot_web/page/editor_layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid.{type Uuid}

pub fn view(
  model: Model,
  current_user_id: option.Option(Uuid),
  now: Timestamp,
) -> Element(Msg) {
  case model {
    Lifecycle(model) -> lifecycle_view.view(model)
    Ready(model) ->
      view_helper(model, current_user_id, now)
      |> element.map(EditorMessage)
  }
}

fn view_helper(
  model: Editor,
  current_user_id: option.Option(Uuid),
  now: Timestamp,
) -> Element(EditorMsg) {
  let can_edit_title =
    language.is_writable(model.snippet.language)
    && {
      model.snippet.slug == option.None
      || policy.is_owner(model, current_user_id)
    }
  let show_snippet_info = model.snippet.slug != option.None
  editor_layout.shell(
    load_ad: True,
    title: model.snippet.title,
    title_actions: [
      case show_snippet_info {
        True ->
          editor_layout.title_hint_button(
            class_name: "editor-page__title-edit-button editor-page__title-info-button",
            aria_label: "Snippet info",
            hint_class: "editor-page__title-hint editor-page__title-hint--info",
            hint_label: "Info",
            attributes: [event.on_click(SnippetInfo(SnippetInfoClicked))],
          )

        False -> html.div([], [])
      },
      case can_edit_title {
        True ->
          editor_layout.title_hint_button(
            class_name: "editor-page__title-edit-button",
            aria_label: "Edit snippet metadata",
            hint_class: "editor-page__title-hint",
            hint_label: "Edit",
            attributes: [event.on_click(Metadata(EditMetadataClicked))],
          )

        False -> html.div([], [])
      },
    ],
    pre_tabbar_children: case language.is_writable(model.snippet.language) {
      True -> [
        metadata_dialog_view.view(model) |> element.map(Metadata),
        file_dialog_view.add_dialog(model) |> element.map(File),
        file_dialog_view.edit_dialog(model) |> element.map(File),
        settings_dialog_view.view(model) |> element.map(Settings),
        save_dialog_view.view(model, current_user_id) |> element.map(Save),
        restore_draft_view.view(model, now) |> element.map(RestoreDraft),
        snippet_info_view.dialog(model) |> element.map(SnippetInfo),
      ]
      False -> [snippet_info_view.dialog(model) |> element.map(SnippetInfo)]
    },
    tabbar_children: workspace_toolbar_view.view(model),
    active_tab_id: tab_semantics.tab_id(model.workspace.selected_tab),
    editor: element.element(
      "glot-codemirror",
      [
        attribute.id(ids.editor),
        attribute.class("editor-shell__codemirror"),
        attribute.attribute(
          "language",
          language.to_string(model.snippet.language),
        ),
        attribute.attribute(
          "editor-external-revision",
          int.to_string(model.workspace.editor_external_revision),
        ),
        attribute.attribute(
          "editor-revision",
          int.to_string(model.workspace.editor_revision),
        ),
        attribute.attribute(
          "value",
          document.selected_content(
            model.snippet.files,
            model.snippet.stdin,
            model.workspace.selected_tab,
          ),
        ),
        attribute.disabled(!language.is_writable(model.snippet.language)),
        attribute.attribute(
          "keyboard-bindings",
          model.editor_settings.keyboard_bindings
            |> editor_settings.keyboard_bindings_to_string(),
        ),
        event.on("change", {
          use value <- decode.subfield(["detail", "value"], decode.string)
          use revision <- decode.subfield(["detail", "revision"], decode.int)
          decode.success(Execution(SourceCodeChanged(value, revision)))
        }),
        event.on("editor-run", decode.success(Execution(RunSubmitted))),
      ],
      [],
    ),
    action_buttons: [
      action_button(
        "editor-shell__action-button",
        run_button_text(model),
        !language.is_runnable(model.snippet.language)
          || operations.execution_is_running(model.operations)
          && !operations.execution_cancellation_is_available(model.operations),
        case operations.execution_cancellation_is_available(model.operations) {
          True -> Execution(RunCancellationSubmitted)
          False -> Execution(RunSubmitted)
        },
      ),
      action_button(
        "editor-shell__action-button",
        save_button_text(model),
        !language.is_writable(model.snippet.language)
          || operations.save_is_saving(model.operations),
        Save(SaveClicked),
      ),
    ],
    console: console_view.view(model.operations),
  )
}

fn run_button_text(model: Editor) -> String {
  case
    language.is_runnable(model.snippet.language),
    operations.execution_is_running(model.operations)
  {
    False, _ -> "Not runnable"
    True, True ->
      case operations.execution_cancellation_is_available(model.operations) {
        True -> "Cancel"
        False -> "Running..."
      }
    True, False -> "Run"
  }
}

fn save_button_text(model: Editor) -> String {
  case
    language.is_writable(model.snippet.language),
    operations.save_is_saving(model.operations)
  {
    False, _ -> "Read only"
    True, True -> "Saving..."
    True, False -> "Save"
  }
}

fn action_button(
  class_name: String,
  label: String,
  disabled: Bool,
  msg: EditorMsg,
) -> Element(EditorMsg) {
  editor_layout.shell_button(
    class_name: class_name,
    attributes: [attribute.disabled(disabled), event.on_click(msg)],
    children: [html.text(label)],
  )
}
