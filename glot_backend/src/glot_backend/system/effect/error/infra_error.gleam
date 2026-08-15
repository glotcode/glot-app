import glot_backend/system/effect/error/db_error
import glot_core/job/job_model

pub type DatabaseOperation {
  QueryOperation
  CommandOperation
  TransactionOperation
}

pub type Retryability {
  Retryable
  NonRetryable
}

pub type FailureDisposition {
  PermanentFailure
  RetryWithBackoff
  RetryAfter(seconds: Int)
  RetryIndefinitelyWithBackoff
  RetryIndefinitelyAfter(seconds: Int)
}

pub type SpamClassifierFailureScope {
  SnippetFailure
  ServiceFailure
}

pub type EmailError {
  EmailTemplateMissing(name: String)
  EmailTemplateRenderFailed(message: String)
  EmailDeliveryFailed(detail: String, retryability: Retryability)
}

pub type SpamClassifierError {
  SpamClassifierRequestFailed(
    detail: String,
    disposition: FailureDisposition,
    scope: SpamClassifierFailureScope,
  )
}

pub type InfraError {
  DatabaseError(operation: DatabaseOperation, message: String)
  RunRequestClientError(message: String)
  RunRequestServerError
  EmailError(EmailError)
  JobTimeoutExceeded
  JobInterruptedForShutdown
  JobPayloadMissing(job_type: job_model.JobType)
  SpamClassifierError(SpamClassifierError)
}

pub fn status(err: InfraError) -> Int {
  case err {
    RunRequestClientError(_) -> 400
    _ -> 500
  }
}

pub fn code(err: InfraError) -> String {
  case err {
    DatabaseError(operation, _) ->
      case operation {
        QueryOperation -> "database_query_error"
        CommandOperation -> "database_command_error"
        TransactionOperation -> "database_transaction_error"
      }
    RunRequestClientError(_) -> "run_request_client_error"
    RunRequestServerError -> "run_request_server_error"
    EmailError(_) -> "send_email_error"
    JobTimeoutExceeded -> "job_timeout_exceeded"
    JobInterruptedForShutdown -> "job_interrupted_for_shutdown"
    JobPayloadMissing(_) -> "job_payload_missing"
    SpamClassifierError(_) -> "spam_classifier_error"
  }
}

pub fn message(err: InfraError) -> String {
  case err {
    DatabaseError(operation, _) ->
      case operation {
        QueryOperation -> "Failed to query data"
        CommandOperation -> "Failed to run command"
        TransactionOperation -> "Transaction failed"
      }
    RunRequestClientError(message) -> message
    RunRequestServerError -> "Failed to run code"
    EmailError(_) -> "Failed to send email"
    JobTimeoutExceeded -> "Job timed out"
    JobInterruptedForShutdown -> "Job interrupted for shutdown"
    JobPayloadMissing(_) -> "Job payload missing"
    SpamClassifierError(_) -> "Spam classification failed"
  }
}

pub fn to_string(err: InfraError) -> String {
  case err {
    DatabaseError(operation, message) ->
      case operation {
        QueryOperation -> "query_error:" <> message
        CommandOperation -> "command_error:" <> message
        TransactionOperation -> "transaction_error:" <> message
      }
    RunRequestClientError(message) -> "run_error_client:" <> message
    RunRequestServerError -> "run_error_server"
    EmailError(email_error) ->
      case email_error {
        EmailTemplateMissing(name) -> "send_email_missing_template:" <> name
        EmailTemplateRenderFailed(message) ->
          "send_email_render_failed:" <> message
        EmailDeliveryFailed(detail, _) ->
          "send_email_delivery_failed:" <> detail
      }
    JobTimeoutExceeded -> "job_timeout_exceeded"
    JobInterruptedForShutdown -> "job_interrupted_for_shutdown"
    JobPayloadMissing(job_type) ->
      "job_payload_missing:" <> job_model.job_type_to_string(job_type)
    SpamClassifierError(SpamClassifierRequestFailed(detail, _, _)) ->
      "spam_classifier_request_failed:" <> detail
  }
}

pub fn from_query_error(err: db_error.DbQueryError) -> InfraError {
  let db_error.DbQueryError(message: message) = err
  DatabaseError(QueryOperation, message)
}

pub fn from_command_error(err: db_error.DbCommandError) -> InfraError {
  let db_error.DbCommandError(message: message) = err
  DatabaseError(CommandOperation, message)
}

pub fn from_transaction_error(err: db_error.DbTransactionError) -> InfraError {
  let db_error.DbTransactionError(message: message) = err
  DatabaseError(TransactionOperation, message)
}

pub fn retryable(err: InfraError) -> Bool {
  case failure_disposition(err) {
    PermanentFailure -> False
    RetryWithBackoff
    | RetryAfter(_)
    | RetryIndefinitelyWithBackoff
    | RetryIndefinitelyAfter(_) -> True
  }
}

pub fn failure_disposition(err: InfraError) -> FailureDisposition {
  case err {
    DatabaseError(_, _) -> RetryWithBackoff
    RunRequestClientError(_) -> PermanentFailure
    RunRequestServerError -> RetryWithBackoff
    EmailError(email_error) ->
      case email_error_retryable(email_error) {
        True -> RetryWithBackoff
        False -> PermanentFailure
      }
    JobTimeoutExceeded -> RetryWithBackoff
    JobInterruptedForShutdown -> RetryWithBackoff
    JobPayloadMissing(_) -> PermanentFailure
    SpamClassifierError(SpamClassifierRequestFailed(_, disposition, _)) ->
      disposition
  }
}

fn email_error_retryable(err: EmailError) -> Bool {
  case err {
    EmailTemplateMissing(_) -> False
    EmailTemplateRenderFailed(_) -> False
    EmailDeliveryFailed(_, retryability) ->
      case retryability {
        Retryable -> True
        NonRetryable -> False
      }
  }
}
