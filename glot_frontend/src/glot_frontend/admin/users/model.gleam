import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/auth/account_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import glot_core/loadable
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/mutation
import youid/uuid

pub type Model {
  Model(
    id: uuid.Uuid,
    user: loadable.Loadable(UserEditor),
    pending_delete: option.Option(UserEditor),
    delete_state: DeleteState,
    save_generation: Generation(SaveStream),
    delete_generation: Generation(DeleteStream),
  )
}

pub type SaveStream {
  SaveStream
}

pub type DeleteStream {
  DeleteStream
}

pub type DeleteState {
  DeleteIdle
  Deleting
}

pub type UserEditor {
  UserEditor(
    id: uuid.Uuid,
    account_id: uuid.Uuid,
    email: email_address_model.EmailAddress,
    saved: UserFields,
    draft: UserFields,
    metadata: UserMetadata,
    state: mutation.MutationState,
  )
}

pub type UserFields {
  UserFields(
    username: String,
    role: user_model.UserRole,
    account_state: account_model.AccountState,
    account_state_reason: String,
    account_tier: account_model.AccountTier,
  )
}

pub type UserMetadata {
  UserMetadata(
    delete_job_id: option.Option(uuid.Uuid),
    delete_scheduled_at: option.Option(Timestamp),
    last_login_at: Timestamp,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.user)
}
