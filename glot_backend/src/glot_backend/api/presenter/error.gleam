import gleam/int
import gleam/json
import gleam/option
import glot_backend/auth/error as auth_error
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/error/policy_error
import glot_backend/system/effect/error/request_error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/request/context
import glot_core/api_action
import glot_core/api_error_dto
import glot_core/auth/account_model
import glot_core/job/job_model
import wisp

pub fn to_response(ctx: context.Context, err: error.Error) -> wisp.Response {
  let #(status, code, message) = error_details(err)

  case err {
    error.RequestError(request_error.Validation(validation_error)) -> {
      wisp.log_error(
        "Validation error: "
        <> request_error.validation_message(validation_error),
      )
      error_response(ctx, status, code, message)
    }
    error.RequestError(_) -> error_response(ctx, status, code, message)
    error.ResourceError(resource_error) -> {
      wisp.log_error(
        case resource_error.status(resource_error) {
          404 -> "Not found error: "
          _ -> "Conflict error: "
        }
        <> resource_error.code(resource_error),
      )
      error_response(ctx, status, code, message)
    }
    error.AuthError(auth_error) -> {
      wisp.log_error(auth_log_message(auth_error))
      error_response(ctx, status, code, message)
    }
    error.PolicyError(policy_error.ForbiddenAccountState(action, account_state)) -> {
      wisp.log_error(
        "Account state error: "
        <> account_model.account_state_to_string(account_state)
        <> " not allowed for "
        <> api_action.to_string(action),
      )
      error_response(ctx, status, code, message)
    }
    error.PolicyError(policy_error) -> {
      let response = error_response(ctx, status, code, message)
      let response = case policy_error.retry_after_seconds(policy_error) {
        option.Some(seconds) ->
          wisp.set_header(response, "Retry-After", int.to_string(seconds))
        option.None -> response
      }
      wisp.log_error("Availability error: " <> policy_error.code(policy_error))
      response
    }
    error.InfraError(infra_error.DatabaseError(operation, detail)) -> {
      let label = case operation {
        infra_error.QueryOperation -> "Query error: "
        infra_error.CommandOperation -> "Command error: "
        infra_error.TransactionOperation -> "Transaction error: "
      }
      wisp.log_error(label <> detail)
      error_response(ctx, status, code, message)
    }
    error.InfraError(infra_error.RunRequestClientError(detail)) -> {
      wisp.log_error("Run request error (client): " <> detail)
      error_response(ctx, status, code, message)
    }
    error.InfraError(infra_error.RunRequestServerError) -> {
      wisp.log_error("Run request error (server)")
      error_response(ctx, status, code, message)
    }
    error.InfraError(infra_error.EmailError(_)) -> {
      wisp.log_error("Send email error")
      error_response(ctx, status, code, message)
    }
    error.InfraError(infra_error.JobTimeoutExceeded) -> {
      wisp.log_error("Job timeout exceeded")
      error_response(ctx, status, code, message)
    }
    error.InfraError(infra_error.JobPayloadMissing(job_type)) -> {
      wisp.log_error(
        "Job payload missing for " <> job_model.job_type_to_string(job_type),
      )
      error_response(ctx, status, code, message)
    }
  }
}

pub fn error_status(err: error.Error) -> Int {
  let #(status, _, _) = error_details(err)
  status
}

pub fn error_details(err: error.Error) -> #(Int, String, String) {
  case err {
    error.RequestError(request_error) -> #(
      request_error.status(request_error),
      request_error.code(request_error),
      request_error.message(request_error),
    )
    error.ResourceError(resource_error) -> #(
      resource_error.status(resource_error),
      resource_error.code(resource_error),
      resource_error.message(resource_error),
    )
    error.AuthError(auth_error) -> #(
      auth_error.status(auth_error),
      auth_error.code(auth_error),
      auth_error.message(auth_error),
    )
    error.PolicyError(policy_error) -> #(
      policy_error.status(policy_error),
      policy_error.code(policy_error),
      policy_error.message(policy_error),
    )
    error.InfraError(infra_error) -> #(
      infra_error.status(infra_error),
      infra_error.code(infra_error),
      infra_error.message(infra_error),
    )
  }
}

fn error_response(
  ctx: context.Context,
  status: Int,
  code: String,
  message: String,
) -> wisp.Response {
  wisp.json_response(
    json.to_string(
      api_error_dto.encode(api_error_dto.ApiError(
        code: code,
        message: message,
        request_id: ctx.request_id,
      )),
    ),
    status,
  )
}

fn auth_log_message(err: auth_error.AuthError) -> String {
  case err {
    auth_error.InvalidLoginToken -> "Login error: invalid token"
    auth_error.LoginTokenUsed -> "Login error: token used"
    auth_error.LoginTokenExpired -> "Login error: token expired"
    auth_error.PasskeyChallengeNotFound -> "Passkey error: challenge not found"
    auth_error.PasskeyChallengeExpired -> "Passkey error: challenge expired"
    auth_error.InvalidPasskeyAssertion -> "Passkey error: invalid assertion"
    auth_error.MissingSessionToken -> "Session error: missing session token"
    auth_error.SessionNotFound -> "Session error: session not found"
    auth_error.SessionExpired -> "Session error: session expired"
    auth_error.MissingUserIdAndIp -> "Client info error: missing user_id and ip"
    auth_error.AuthenticationRequired ->
      "Authorization error: authentication required"
    auth_error.NotOwner -> "Authorization error: not owner"
    auth_error.AdminRequired -> "Authorization error: admin required"
    auth_error.InvalidEmailChangeToken ->
      "Email change error: invalid verification code"
    auth_error.EmailAlreadyInUse -> "Email change error: email already in use"
    auth_error.EmailUnchanged -> "Email change error: email unchanged"
    auth_error.EmailChangeBlockedByPendingDeletion ->
      "Email change error: account deletion pending"
  }
}
