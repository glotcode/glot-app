import gleam/int
import gleam/list
import gleam/option
import gleam/result
import glot_core/admin/job_type_policy_dto
import glot_core/loadable
import glot_frontend/admin/jobs/policies_model.{
  type Field, type Model, type PolicyEditor, type PolicyFields,
  BaseBackoffSecondsField, MaxAttemptsField, MaxBackoffSecondsField,
  PolicyEditor, PolicyFields, QueueNameField, TimeoutSecondsField,
}
import glot_frontend/admin/ui/format as admin_format
import glot_frontend/request_generation
import glot_frontend/ui/mutation

pub fn editor_from_response(
  response: job_type_policy_dto.JobTypePolicyResponse,
) -> PolicyEditor {
  let fields = fields_from_response(response)

  PolicyEditor(
    job_type: response.job_type,
    saved: fields,
    draft: fields,
    state: mutation.Idle,
    save_generation: request_generation.initial(),
  )
}

fn fields_from_response(
  response: job_type_policy_dto.JobTypePolicyResponse,
) -> PolicyFields {
  PolicyFields(
    queue_name: response.queue_name,
    max_attempts: int.to_string(response.max_attempts),
    timeout_seconds: int.to_string(response.timeout_seconds),
    base_backoff_seconds: int.to_string(response.base_backoff_seconds),
    max_backoff_seconds: int.to_string(response.max_backoff_seconds),
  )
}

pub fn request_from_editor(
  editor: PolicyEditor,
) -> Result(job_type_policy_dto.UpsertJobTypePolicyRequest, String) {
  use max_attempts <- result.try(admin_format.parse_positive_int(
    editor.draft.max_attempts,
    "Max attempts",
  ))
  use _ <- result.try(validate_queue(editor.draft.queue_name))
  use timeout_seconds <- result.try(admin_format.parse_positive_int(
    editor.draft.timeout_seconds,
    "Timeout seconds",
  ))
  use base_backoff_seconds <- result.try(admin_format.parse_positive_int(
    editor.draft.base_backoff_seconds,
    "Base backoff",
  ))
  use max_backoff_seconds <- result.try(admin_format.parse_positive_int(
    editor.draft.max_backoff_seconds,
    "Max backoff",
  ))

  case base_backoff_seconds > max_backoff_seconds {
    True -> Error("Base backoff must be less than or equal to max backoff.")
    False ->
      Ok(job_type_policy_dto.UpsertJobTypePolicyRequest(
        job_type: editor.job_type,
        queue_name: editor.draft.queue_name,
        max_attempts: max_attempts,
        timeout_seconds: timeout_seconds,
        base_backoff_seconds: base_backoff_seconds,
        max_backoff_seconds: max_backoff_seconds,
      ))
  }
}

pub fn update_editor(
  editors: List(PolicyEditor),
  job_type: String,
  update: fn(PolicyEditor) -> PolicyEditor,
) -> List(PolicyEditor) {
  list.map(editors, fn(editor) {
    case editor.job_type == job_type {
      True -> update(editor)
      False -> editor
    }
  })
}

pub fn find_editor(
  editors: List(PolicyEditor),
  job_type: String,
) -> option.Option(PolicyEditor) {
  editors
  |> list.filter(fn(editor) { editor.job_type == job_type })
  |> list.first
  |> option.from_result()
}

pub fn update_field(
  fields: PolicyFields,
  field: Field,
  value: String,
) -> PolicyFields {
  case field {
    QueueNameField -> PolicyFields(..fields, queue_name: value)
    MaxAttemptsField -> PolicyFields(..fields, max_attempts: value)
    TimeoutSecondsField -> PolicyFields(..fields, timeout_seconds: value)
    BaseBackoffSecondsField ->
      PolicyFields(..fields, base_backoff_seconds: value)
    MaxBackoffSecondsField -> PolicyFields(..fields, max_backoff_seconds: value)
  }
}

fn validate_queue(queue: String) -> Result(Nil, String) {
  case queue {
    "default" | "spam_classifier" -> Ok(Nil)
    _ -> Error("Queue must be default or spam_classifier.")
  }
}

pub fn loaded_policies(model: Model) -> List(PolicyEditor) {
  case model.policies {
    loadable.Loaded(policies) -> policies
    loadable.NotLoaded | loadable.Loading | loadable.LoadError(_) -> []
  }
}
