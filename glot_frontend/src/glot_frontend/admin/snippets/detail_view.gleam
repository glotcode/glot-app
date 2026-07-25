import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import glot_core/admin/snippet_dto
import glot_core/language
import glot_core/loadable
import glot_core/route
import glot_core/snippet/snippet_model
import glot_frontend/admin/snippets/detail_constants as constants
import glot_frontend/admin/snippets/detail_message.{
  type Msg, DeleteCancelled, DeleteClicked, DeleteConfirmed, DeleteDialogClosed,
}
import glot_frontend/admin/snippets/detail_model.{
  type Model, DeleteIdle, Deleting,
}
import glot_frontend/admin/ui/dialog as admin_dialog
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/status as admin_status
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    admin_layout.page_with_panel_class(
      panel_class: "admin-job-page",
      title: "Snippet detail",
      intro: "",
      actions: [
        admin_layout.secondary_link(
          [web_route.href(route.Public(route.Snippet(model.slug)))],
          "Open public snippet",
        ),
        html.button(
          [
            attribute.type_("button"),
            attribute.class("admin-page__button admin-page__button--danger"),
            attribute.disabled(model.delete_state == Deleting),
            event.on_click(DeleteClicked),
          ],
          [
            html.text(case model.delete_state {
              Deleting -> "Deleting..."
              DeleteIdle -> "Delete snippet"
            }),
          ],
        ),
      ],
      content: [snippet_status(model), detail_view(model)],
    ),
    delete_confirmation_dialog(model),
  ])
}

fn snippet_status(model: Model) -> Element(Msg) {
  case model.snippet, model.delete_state {
    loadable.LoadError(message), _ -> admin_status.error_status(message)
    loadable.Loading, _ -> admin_status.status("Loading snippet...")
    _, Deleting -> admin_status.status("Deleting snippet...")
    _, DeleteIdle -> admin_status.status("")
  }
}

fn detail_view(model: Model) -> Element(Msg) {
  loadable.fold(
    model.snippet,
    admin_status.empty_state("This snippet could not be loaded."),
    admin_status.empty_state("Loading snippet..."),
    fn(snippet) {
      html.div([attribute.class("admin-job-page__content")], [
        html.div([attribute.class(admin_layout.summary_grid_class())], [
          admin_layout.summary_card("Title", snippet.title),
          admin_layout.summary_card("Owner", snippet.user.username),
          admin_layout.summary_card("Language", language.name(snippet.language)),
          admin_layout.summary_card(
            "Visibility",
            visibility_text(snippet.visibility),
          ),
          admin_layout.summary_card("Slug", snippet.slug),
          admin_layout.summary_card(
            "Files",
            int.to_string(list.length(snippet.files)),
          ),
        ]),
        html.div([attribute.class("admin-page__group")], [
          html.div([attribute.class("admin-page__group-header")], [
            html.h3([attribute.class("admin-page__group-title")], [
              html.text("Snippet"),
            ]),
            html.p([attribute.class("admin-page__group-copy")], [
              html.text(
                "Metadata is kept separate from file contents so the page can grow with future admin actions.",
              ),
            ]),
          ]),
          html.div([attribute.class(admin_layout.detail_grid_class())], [
            admin_layout.detail_item("Snippet ID", uuid.to_string(snippet.id)),
            admin_layout.detail_item("Slug", snippet.slug),
            admin_layout.detail_item("Owner", snippet.user.username),
            admin_layout.detail_item(
              "Owner ID",
              uuid.to_string(snippet.user.id),
            ),
            admin_layout.detail_item(
              "Language",
              language.name(snippet.language),
            ),
            admin_layout.detail_item(
              "Visibility",
              visibility_text(snippet.visibility),
            ),
            admin_layout.detail_item(
              "Created at",
              admin_format.format_timestamp(snippet.created_at),
            ),
            admin_layout.detail_item(
              "Updated at",
              admin_format.format_timestamp(snippet.updated_at),
            ),
          ]),
        ]),
        html.div([attribute.class("admin-page__group")], [
          html.div([attribute.class("admin-page__group-header")], [
            html.h3([attribute.class("admin-page__group-title")], [
              html.text("Run configuration"),
            ]),
            html.p([attribute.class("admin-page__group-copy")], [
              html.text(
                "Run instructions and stdin are shown directly as stored, without editor dependencies.",
              ),
            ]),
          ]),
          html.div([attribute.class(admin_layout.detail_grid_class())], [
            admin_layout.detail_item(
              "Run command",
              optional_run_command(snippet.run_instructions),
            ),
            admin_layout.detail_item(
              "Build commands",
              build_commands_text(snippet.run_instructions),
            ),
          ]),
          html.div([attribute.class("admin-page__policy")], [
            html.span([attribute.class("admin-info-label")], [
              html.text("stdin"),
            ]),
            html.pre([attribute.class("admin-page__code-block")], [
              html.text(empty_text(snippet.stdin)),
            ]),
          ]),
        ]),
        html.div([attribute.class("admin-page__group")], [
          html.div([attribute.class("admin-page__group-header")], [
            html.h3([attribute.class("admin-page__group-title")], [
              html.text("Files"),
            ]),
            html.p([attribute.class("admin-page__group-copy")], [
              html.text(
                "Each stored file is rendered as plain text for a low-maintenance admin review workflow.",
              ),
            ]),
          ]),
          html.div([attribute.class("admin-snippet-page__files")], {
            snippet.files |> list.map(file_view)
          }),
        ]),
      ])
    },
    fn(_) { admin_status.empty_state("This snippet could not be loaded.") },
  )
}

fn file_view(file: snippet_model.File) -> Element(Msg) {
  html.div([attribute.class("admin-page__policy admin-snippet-page__file")], [
    html.div([attribute.class("admin-snippet-page__file-header")], [
      html.span([attribute.class("admin-info-label")], [
        html.text("File"),
      ]),
      html.strong([attribute.class("admin-snippet-page__file-name")], [
        html.text(file.name),
      ]),
    ]),
    html.pre([attribute.class("admin-page__code-block")], [
      html.code([], [html.text(empty_text(file.content))]),
    ]),
  ])
}

fn delete_confirmation_dialog(model: Model) -> Element(Msg) {
  html.dialog(
    [
      attribute.id(constants.delete_dialog_id),
      attribute.class("app-dialog"),
      attribute.attribute("aria-label", "Delete snippet"),
      event.on("close", decode.success(DeleteDialogClosed)),
    ],
    delete_confirmation_dialog_children(model.pending_delete),
  )
}

fn delete_confirmation_dialog_children(
  pending_delete: option.Option(snippet_dto.SnippetDetailResponse),
) -> List(Element(Msg)) {
  case pending_delete {
    option.Some(snippet) -> [
      admin_dialog.dialog_form([], [
        admin_dialog.dialog_intro("Delete snippet", [
          html.text("Delete "),
          html.code([], [html.text(snippet.title)]),
          html.text("? This action cannot be undone."),
        ]),
        admin_dialog.dialog_actions([
          admin_dialog.dialog_cancel_button(
            [
              attribute.type_("button"),
              attribute.autofocus(True),
              event.on_click(DeleteCancelled),
            ],
            "Cancel",
          ),
          admin_dialog.dialog_danger_button(
            [
              attribute.type_("button"),
              event.on_click(DeleteConfirmed),
            ],
            "Delete snippet",
          ),
        ]),
      ]),
    ]
    option.None -> []
  }
}

fn optional_run_command(
  instructions: option.Option(language.RunInstructions),
) -> String {
  case instructions {
    option.Some(instructions) -> instructions.run_command
    option.None -> "None"
  }
}

fn build_commands_text(
  instructions: option.Option(language.RunInstructions),
) -> String {
  case instructions {
    option.Some(instructions) ->
      case instructions.build_commands {
        [] -> "None"
        commands -> string.join(commands, with: ", ")
      }
    option.None -> "None"
  }
}

fn visibility_text(visibility: snippet_model.Visibility) -> String {
  case visibility {
    snippet_model.Public -> "Public"
    snippet_model.Unlisted -> "Unlisted"
    snippet_model.Secret -> "Secret"
  }
}

fn empty_text(value: String) -> String {
  case value == "" {
    True -> "Empty"
    False -> value
  }
}
