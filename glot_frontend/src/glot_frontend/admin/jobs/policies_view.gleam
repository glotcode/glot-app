import gleam/list
import glot_core/loadable
import glot_frontend/admin/jobs/policies_message.{
  type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/jobs/policies_model.{
  type Model, type PolicyEditor, BaseBackoffSecondsField, MaxAttemptsField,
  MaxBackoffSecondsField, QueueNameField, TimeoutSecondsField,
}
import glot_frontend/admin/jobs/ui as admin_job_ui
import glot_frontend/admin/ui/form as admin_form
import glot_frontend/admin/ui/layout as admin_layout
import glot_frontend/admin/ui/status as admin_status
import glot_frontend/ui/mutation
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  admin_layout.page(
    title: "Job type policies",
    intro: "Tune queue retry and timeout defaults per job type. New jobs inherit these values when they are enqueued.",
    content: [
      admin_status.loadable_status(
        model.policies,
        "Loading job type policies...",
      ),
      policies_content(model),
    ],
  )
}

fn policies_content(model: Model) -> Element(Msg) {
  loadable.fold(
    model.policies,
    admin_status.empty_state("No job type policies were returned."),
    admin_status.empty_state("Loading job type policies..."),
    fn(policies) {
      case policies {
        [] -> admin_status.empty_state("No job type policies were returned.")
        _ ->
          html.div(
            [attribute.class("admin-page__section-grid")],
            list.map(policies, policy_card),
          )
      }
    },
    fn(_) { admin_status.empty_state("No job type policies were returned.") },
  )
}

fn policy_card(editor: PolicyEditor) -> Element(Msg) {
  let dirty = editor.draft != editor.saved
  let save_disabled = mutation.is_saving(editor.state) || !dirty

  html.article(
    [attribute.class("admin-page__policy admin-page__policy--config")],
    [
      html.div([attribute.class("admin-page__policy-header")], [
        html.div([], [
          html.h3([attribute.class("admin-page__policy-title")], [
            html.text(admin_job_ui.job_type_label(editor.job_type)),
          ]),
          html.p([attribute.class("admin-page__policy-subtitle")], [
            html.text(editor.job_type),
          ]),
        ]),
        badge_for_editor(editor, dirty),
      ]),
      html.div([attribute.class("admin-page__field-grid")], [
        admin_form.select_input(
          label: "Queue",
          help: "Execution pool for this job type.",
          value: editor.draft.queue_name,
          on_input: fn(value) {
            FieldChanged(editor.job_type, QueueNameField, value)
          },
          options: [
            #("default", "Default"),
            #("spam_classifier", "Spam classifier"),
          ],
        ),
        admin_form.text_input(
          label: "Max attempts",
          help: "Retry limit for new jobs of this type.",
          value: editor.draft.max_attempts,
          placeholder: "3",
          on_input: fn(value) {
            FieldChanged(editor.job_type, MaxAttemptsField, value)
          },
        ),
        admin_form.text_input(
          label: "Timeout seconds",
          help: "Maximum execution time before the job fails.",
          value: editor.draft.timeout_seconds,
          placeholder: "60",
          on_input: fn(value) {
            FieldChanged(editor.job_type, TimeoutSecondsField, value)
          },
        ),
        admin_form.text_input(
          label: "Base backoff",
          help: "Initial retry delay in seconds.",
          value: editor.draft.base_backoff_seconds,
          placeholder: "10",
          on_input: fn(value) {
            FieldChanged(editor.job_type, BaseBackoffSecondsField, value)
          },
        ),
        admin_form.text_input(
          label: "Max backoff",
          help: "Maximum retry delay in seconds.",
          value: editor.draft.max_backoff_seconds,
          placeholder: "300",
          on_input: fn(value) {
            FieldChanged(editor.job_type, MaxBackoffSecondsField, value)
          },
        ),
      ]),
      html.div([attribute.class("admin-page__policy-footer")], [
        admin_status.mutation_status(
          editor.state,
          "Saving job type policy...",
          "Job type policy saved.",
        ),
        html.div([attribute.class("admin-page__actions")], [
          admin_layout.secondary_button(
            [
              attribute.type_("button"),
              attribute.disabled(mutation.is_saving(editor.state) || !dirty),
              event.on_click(ResetClicked(editor.job_type)),
            ],
            "Reset",
          ),
          html.button(
            [
              attribute.type_("button"),
              attribute.class(admin_layout.primary_button_class()),
              attribute.disabled(save_disabled),
              event.on_click(SaveClicked(editor.job_type)),
            ],
            [html.text(save_button_text(editor.state))],
          ),
        ]),
      ]),
    ],
  )
}

fn badge_for_editor(editor: PolicyEditor, dirty: Bool) -> Element(Msg) {
  case editor.state {
    mutation.SaveError(_) ->
      admin_layout.badge("Error", admin_layout.DangerTone)
    mutation.Saving -> admin_layout.badge("Saving", admin_layout.InfoTone)
    mutation.Saved -> admin_layout.badge("Saved", admin_layout.SuccessTone)
    mutation.Idle ->
      case dirty {
        True -> admin_layout.badge("Unsaved", admin_layout.WarningTone)
        False -> html.div([], [])
      }
  }
}

fn save_button_text(state: mutation.MutationState) -> String {
  case state {
    mutation.Saving -> "Saving..."
    mutation.Idle | mutation.Saved | mutation.SaveError(_) -> "Save policy"
  }
}
