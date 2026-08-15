import gleam/dynamic/decode
import gleam/json
import glot_backend/auth/error as auth_error
import glot_backend/system/effect/error/db_error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/error/policy_error
import glot_backend/system/effect/error/request_error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/error/run_request_error
import glot_core/rate_limit.{type RateLimit}
import glot_core/validation_error

// Public application error surface.
pub type Error {
  RequestError(request_error.RequestError)
  ResourceError(resource_error.ResourceError)
  AuthError(auth_error.AuthError)
  PolicyError(policy_error.PolicyError)
  InfraError(infra_error.InfraError)
}

pub fn to_string(err: Error) -> String {
  case err {
    RequestError(request_error) -> request_error.to_string(request_error)
    ResourceError(resource_error) -> resource_error.to_string(resource_error)
    AuthError(auth_error) -> auth_error.to_string(auth_error)
    PolicyError(policy_error) -> policy_error.to_string(policy_error)
    InfraError(infra_error) -> infra_error.to_string(infra_error)
  }
}

pub fn retryable(err: Error) -> Bool {
  case failure_disposition(err) {
    infra_error.PermanentFailure -> False
    infra_error.RetryWithBackoff
    | infra_error.RetryAfter(_)
    | infra_error.RetryIndefinitelyWithBackoff
    | infra_error.RetryIndefinitelyAfter(_) -> True
  }
}

pub fn failure_disposition(err: Error) -> infra_error.FailureDisposition {
  case err {
    RequestError(_) -> infra_error.PermanentFailure
    ResourceError(resource_error.SpamClassifierConfigNotFound) ->
      infra_error.RetryIndefinitelyAfter(60)
    ResourceError(_) -> infra_error.PermanentFailure
    AuthError(_) -> infra_error.PermanentFailure
    PolicyError(_) -> infra_error.PermanentFailure
    InfraError(err) -> infra_error.failure_disposition(err)
  }
}

pub fn json_parse_error(err: json.DecodeError) -> Error {
  RequestError(request_error.JsonParseError(err))
}

pub fn decode_error(errs: List(decode.DecodeError)) -> Error {
  RequestError(request_error.DecodeError(errs))
}

pub fn validation(err: validation_error.ValidationError) -> Error {
  RequestError(request_error.Validation(err))
}

pub fn too_many_requests(count: Int, rate_limit: RateLimit) -> Error {
  RequestError(request_error.TooManyRequests(count, rate_limit))
}

pub fn resource(err: resource_error.ResourceError) -> Error {
  ResourceError(err)
}

pub fn auth(err: auth_error.AuthError) -> Error {
  AuthError(err)
}

pub fn policy(err: policy_error.PolicyError) -> Error {
  PolicyError(err)
}

pub fn infra(err: infra_error.InfraError) -> Error {
  InfraError(err)
}

pub fn database_query_error(err: db_error.DbQueryError) -> Error {
  infra(infra_error.from_query_error(err))
}

pub fn database_command_error(err: db_error.DbCommandError) -> Error {
  infra(infra_error.from_command_error(err))
}

pub fn database_transaction_error(err: db_error.DbTransactionError) -> Error {
  infra(infra_error.from_transaction_error(err))
}

pub fn run_request_error(err: run_request_error.RunRequestError) -> Error {
  case err {
    run_request_error.ClientRunRequestError(message: message) ->
      infra(infra_error.RunRequestClientError(message))
    run_request_error.ServerRunRequestError ->
      infra(infra_error.RunRequestServerError)
  }
}
