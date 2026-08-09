import gleam/dynamic/decode
import gleam/list
import gleam/option
import glot_core/loadable
import glot_core/public_action
import glot_core/rate_limit
import glot_frontend/admin/rate_limits/constants
import glot_frontend/admin/rate_limits/message.{
  type Msg, CancelClicked, EditDialogClosed, FieldChanged, SaveClicked,
  TabSelected,
}
import glot_frontend/admin/rate_limits/model.{
  type ActiveEditor, type EditorTab, type LimitFields, type Model,
  type PolicyEditor, type PolicyTabs, ActiveEditor, AnonymousTab, FreePlusTab,
  FreeTab,
}
import glot_frontend/admin/ui/dialog as admin_dialog
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/ui/mutation
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.dialog(
    [
      attribute.id(constants.edit_dialog_id),
      attribute.class("app-dialog admin-page__dialog"),
      attribute.attribute("aria-label", "Edit rate limit policy"),
      event.on("close", decode.success(EditDialogClosed)),
    ],
    [
      case active_policy(model) {
        option.Some(#(policy, ActiveEditor(action:, tab: active_tab))) ->
          edit_dialog_form(policy, action, active_tab)
        option.None -> html.div([], [])
      },
    ],
  )
}

fn edit_dialog_form(
  policy: PolicyEditor,
  action: public_action.PublicAction,
  active_tab: EditorTab,
) -> Element(Msg) {
  let active_fields = tab_fields(policy.draft_tabs, active_tab)

  admin_dialog.dialog_form([event.on_submit(fn(_) { SaveClicked(action) })], [
    admin_dialog.dialog_section([
      admin_dialog.dialog_header_with_close(
        title: action_label(action),
        copy: "Leave an input empty to remove that limit for the selected tab.",
        close_attributes: [event.on_click(CancelClicked)],
        close_label: "Close",
      ),
      tab_buttons(action, active_tab),
      html.div([attribute.class("admin-page__modal-grid")], [
        unit_input(
          action,
          active_tab,
          rate_limit.Second,
          "Per second",
          active_fields.second,
        ),
        unit_input(
          action,
          active_tab,
          rate_limit.Minute,
          "Per minute",
          active_fields.minute,
        ),
        unit_input(
          action,
          active_tab,
          rate_limit.Hour,
          "Per hour",
          active_fields.hour,
        ),
        unit_input(
          action,
          active_tab,
          rate_limit.Day,
          "Per day",
          active_fields.day,
        ),
      ]),
      admin_layout.form_status_block(modal_status(policy)),
    ]),
    admin_dialog.dialog_actions([
      admin_dialog.dialog_cancel_button(
        [
          attribute.type_("button"),
          event.on_click(CancelClicked),
        ],
        "Cancel",
      ),
      admin_dialog.dialog_primary_button(
        [
          attribute.type_("submit"),
          attribute.disabled(mutation.is_saving(policy.state)),
        ],
        "Save",
      ),
    ]),
  ])
}

fn tab_buttons(
  action: public_action.PublicAction,
  active_tab: EditorTab,
) -> Element(Msg) {
  html.div([attribute.class("admin-page__tab-row")], [
    tab_button(action, AnonymousTab, active_tab, "Anonymous"),
    tab_button(action, FreeTab, active_tab, "Free"),
    tab_button(action, FreePlusTab, active_tab, "FreePlus"),
  ])
}

fn tab_button(
  action: public_action.PublicAction,
  tab: EditorTab,
  active_tab: EditorTab,
  label: String,
) -> Element(Msg) {
  let class_name = case tab == active_tab {
    True -> "admin-page__chip admin-page__chip--selected"
    False -> "admin-page__chip"
  }

  html.button(
    [
      attribute.type_("button"),
      attribute.class(class_name),
      event.on_click(TabSelected(action, tab)),
    ],
    [html.text(label)],
  )
}

fn unit_input(
  action: public_action.PublicAction,
  tab: EditorTab,
  unit: rate_limit.TimeUnit,
  label: String,
  value: String,
) -> Element(Msg) {
  html.label([attribute.class("admin-page__field")], [
    html.span([attribute.class("admin-page__field-label")], [
      html.text(label),
    ]),
    html.input([
      attribute.type_("text"),
      attribute.class("admin-page__input"),
      attribute.value(value),
      event.on_input(fn(next) { FieldChanged(action, tab, unit, next) }),
    ]),
  ])
}

fn active_policy(model: Model) -> option.Option(#(PolicyEditor, ActiveEditor)) {
  case model.active_editor {
    option.Some(active) ->
      case find_policy(loaded_policies(model), active.action) {
        option.Some(policy) -> option.Some(#(policy, active))
        option.None -> option.None
      }
    option.None -> option.None
  }
}

fn loaded_policies(model: Model) -> List(PolicyEditor) {
  case model.policies {
    loadable.Loaded(policies) -> policies
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> []
  }
}

fn find_policy(
  policies: List(PolicyEditor),
  action: public_action.PublicAction,
) -> option.Option(PolicyEditor) {
  list.find(policies, fn(policy) { policy.action == action })
  |> option.from_result()
}

fn tab_fields(tabs: PolicyTabs, tab: EditorTab) -> LimitFields {
  case tab {
    AnonymousTab -> tabs.anonymous
    FreeTab -> tabs.free
    FreePlusTab -> tabs.free_plus
  }
}

pub fn tabs_is_empty(tabs: PolicyTabs) -> Bool {
  fields_is_empty(tabs.anonymous)
  && fields_is_empty(tabs.free)
  && fields_is_empty(tabs.free_plus)
}

fn fields_is_empty(fields: LimitFields) -> Bool {
  fields.second == ""
  && fields.minute == ""
  && fields.hour == ""
  && fields.day == ""
}

fn is_dirty(policy: PolicyEditor) -> Bool {
  policy.draft_tabs != policy.saved_tabs
}

fn editor_status_text(state: mutation.MutationState, dirty: Bool) -> String {
  case state {
    mutation.Idle ->
      case dirty {
        True -> "Unsaved changes."
        False -> "In sync."
      }
    mutation.Saving -> "Saving..."
    mutation.Saved -> "Saved."
    mutation.SaveError(message) -> message
  }
}

fn editor_status_class(state: mutation.MutationState, dirty: Bool) -> String {
  case state {
    mutation.SaveError(_) ->
      "admin-page__policy-status admin-page__policy-status--error"
    mutation.Idle ->
      case dirty {
        True -> "admin-page__policy-status admin-page__policy-status--dirty"
        False -> "admin-page__policy-status"
      }
    mutation.Saving | mutation.Saved -> "admin-page__policy-status"
  }
}

fn modal_status(policy: PolicyEditor) -> Element(Msg) {
  let dirty = is_dirty(policy)

  case policy.state, dirty {
    mutation.Idle, False -> html.div([], [])
    _, _ ->
      html.p([attribute.class(editor_status_class(policy.state, dirty))], [
        html.text(editor_status_text(policy.state, dirty)),
      ])
  }
}

pub fn action_label(action: public_action.PublicAction) -> String {
  case action {
    public_action.TrackPageviewAction -> "Track pageview"
    public_action.RunAction -> "Run code"
    public_action.GetLanguageVersionAction -> "Get language version"
    public_action.GetSessionAction -> "Get session"
    public_action.RefreshSessionAction -> "Refresh session"
    public_action.LogoutAction -> "Logout"
    public_action.GetAccountAction -> "Get account"
    public_action.ListAccountSessionsAction -> "List account sessions"
    public_action.ListAccountPasskeysAction -> "List account passkeys"
    public_action.UpdateAccountAction -> "Update account"
    public_action.BeginEmailChangeAction -> "Begin email change"
    public_action.ConfirmEmailChangeAction -> "Confirm email change"
    public_action.DeleteAccountSessionAction -> "Delete account session"
    public_action.DeleteAccountPasskeyAction -> "Delete account passkey"
    public_action.ScheduleDeleteAccountAction -> "Schedule account deletion"
    public_action.CancelDeleteAccountAction -> "Cancel account deletion"
    public_action.GetSnippetAction -> "Get snippet"
    public_action.ListPublicSnippetsAction -> "List public snippets"
    public_action.ListSessionSnippetsAction -> "List account snippets"
    public_action.CreateSnippetAction -> "Create snippet"
    public_action.UpdateSnippetAction -> "Update snippet"
    public_action.DeleteSnippetAction -> "Delete snippet"
    public_action.SubmitContactAction -> "Submit contact form"
    public_action.SendLoginTokenAction -> "Send login token"
    public_action.LoginAction -> "Login"
    public_action.BeginPasskeyRegistrationAction -> "Begin passkey registration"
    public_action.FinishPasskeyRegistrationAction ->
      "Finish passkey registration"
    public_action.BeginPasskeyLoginAction -> "Begin passkey login"
    public_action.FinishPasskeyLoginAction -> "Finish passkey login"
  }
}
