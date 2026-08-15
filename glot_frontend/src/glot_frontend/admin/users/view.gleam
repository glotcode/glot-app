import gleam/time/timestamp.{type Timestamp}
import glot_core/email/email_address_model
import glot_core/helpers/timestamp_helpers
import glot_core/loadable
import glot_frontend/admin/snippets/route as snippets_route
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/admin/users/message.{type Msg, DeleteClicked}
import glot_frontend/admin/users/model.{
  type DeleteState, type Model, type UserEditor, DeleteIdle, Deleting,
}
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid

import glot_frontend/admin/users/editor_view

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  html.div([], [
    admin_layout.page_with_panel_class(
      panel_class: "admin-job-page",
      title: "User detail",
      intro: "Review account access and edit persisted user and account settings.",
      actions: user_actions(model),
      content: [user_status(model), detail_view(model, now)],
    ),
    editor_view.delete_dialog(model),
  ])
}

fn user_actions(model: Model) -> List(Element(Msg)) {
  let delete_button =
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
          DeleteIdle -> "Delete account"
        }),
      ],
    )

  case model.user {
    loadable.Loaded(editor) -> [
      admin_layout.secondary_link(
        [web_route.href(snippets_route.for_owner(editor.saved.username))],
        "Snippets",
      ),
      delete_button,
    ]
    _ -> [delete_button]
  }
}

fn user_status(model: Model) -> Element(Msg) {
  case model.user, model.delete_state {
    loadable.LoadError(message), _ -> admin_status.error_status(message)
    loadable.Loading, _ -> admin_status.status("Loading user...")
    _, Deleting -> admin_status.status("Deleting account...")
    _, DeleteIdle -> admin_status.status("")
  }
}

fn detail_view(model: Model, now: Timestamp) -> Element(Msg) {
  loadable.fold(
    model.user,
    admin_status.empty_state("This user could not be loaded."),
    admin_status.empty_state("Loading user..."),
    fn(editor) { user_view(editor, now, model.delete_state) },
    fn(_) { admin_status.empty_state("This user could not be loaded.") },
  )
}

fn user_view(
  editor: UserEditor,
  now: Timestamp,
  delete_state: DeleteState,
) -> Element(Msg) {
  html.div([attribute.class("admin-job-page__content")], [
    html.div([attribute.class(admin_layout.summary_grid_class())], [
      admin_layout.summary_card(
        "Role",
        editor_view.role_text(editor.draft.role),
      ),
      admin_layout.summary_card(
        "Access",
        editor_view.account_state_text(editor.draft.account_state),
      ),
      admin_layout.summary_card(
        "Last login",
        timestamp_helpers.relative_label(editor.metadata.last_login_at, now),
      ),
    ]),
    admin_layout.section(
      title: "Metadata",
      copy: "Identifiers and read-only account attributes.",
      content: html.div([attribute.class(admin_layout.detail_grid_class())], [
        admin_layout.detail_item("User ID", uuid.to_string(editor.id)),
        admin_layout.detail_item(
          "Account ID",
          uuid.to_string(editor.account_id),
        ),
        admin_layout.detail_item(
          "Email",
          email_address_model.to_string(editor.email),
        ),
        admin_layout.detail_item(
          "Account deletion job ID",
          admin_format.optional_uuid(editor.metadata.delete_job_id),
        ),
        admin_layout.detail_item(
          "Account deletion scheduled at",
          admin_format.optional_timestamp(editor.metadata.delete_scheduled_at),
        ),
        admin_layout.detail_item(
          "Created at",
          admin_format.format_timestamp(editor.metadata.created_at),
        ),
        admin_layout.detail_item(
          "Updated at",
          admin_format.format_timestamp(editor.metadata.updated_at),
        ),
      ]),
    ),
    admin_layout.section(
      title: "Editable settings",
      copy: "Changes are persisted to the user and account records for this login identity.",
      content: editor_view.form(editor, delete_state == Deleting),
    ),
  ])
}
