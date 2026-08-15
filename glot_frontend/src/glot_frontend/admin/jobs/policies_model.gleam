import glot_core/loadable
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/mutation

pub type Model {
  Model(
    policies: loadable.Loadable(List(PolicyEditor)),
    load_generation: Generation(LoadStream),
  )
}

pub type PolicyEditor {
  PolicyEditor(
    job_type: String,
    saved: PolicyFields,
    draft: PolicyFields,
    state: mutation.MutationState,
    save_generation: Generation(SaveStream),
  )
}

pub type LoadStream {
  LoadStream
}

pub type SaveStream {
  SaveStream
}

pub type PolicyFields {
  PolicyFields(
    queue_name: String,
    max_attempts: String,
    timeout_seconds: String,
    base_backoff_seconds: String,
    max_backoff_seconds: String,
  )
}

pub type Field {
  QueueNameField
  MaxAttemptsField
  TimeoutSecondsField
  BaseBackoffSecondsField
  MaxBackoffSecondsField
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.policies)
}
