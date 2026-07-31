import gleam/int
import gleam/result
import glot_core/admin/auth_config_dto
import glot_frontend/admin/ui/format as admin_format

pub type Fields {
  Fields(
    login_token_max_age: String,
    session_token_max_age: String,
    session_idle_timeout_seconds: String,
    session_cookie_max_age: String,
    session_refresh_interval_seconds: String,
    session_previous_token_grace_seconds: String,
    session_heartbeat_interval_seconds: String,
  )
}

pub type Field {
  LoginTokenMaxAge
  SessionTokenMaxAge
  SessionIdleTimeout
  SessionCookieMaxAge
  SessionRefreshInterval
  PreviousTokenGrace
  HeartbeatInterval
}

pub fn initial() -> Fields {
  Fields("", "", "", "", "", "", "")
}

pub fn set(fields: Fields, field: Field, value: String) -> Fields {
  case field {
    LoginTokenMaxAge -> Fields(..fields, login_token_max_age: value)
    SessionTokenMaxAge -> Fields(..fields, session_token_max_age: value)
    SessionIdleTimeout -> Fields(..fields, session_idle_timeout_seconds: value)
    SessionCookieMaxAge -> Fields(..fields, session_cookie_max_age: value)
    SessionRefreshInterval ->
      Fields(..fields, session_refresh_interval_seconds: value)
    PreviousTokenGrace ->
      Fields(..fields, session_previous_token_grace_seconds: value)
    HeartbeatInterval ->
      Fields(..fields, session_heartbeat_interval_seconds: value)
  }
}

pub fn from_response(response: auth_config_dto.AuthConfigResponse) -> Fields {
  Fields(
    login_token_max_age: int.to_string(response.login_token_max_age),
    session_token_max_age: int.to_string(response.session_token_max_age),
    session_idle_timeout_seconds: int.to_string(
      response.session_idle_timeout_seconds,
    ),
    session_cookie_max_age: int.to_string(response.session_cookie_max_age),
    session_refresh_interval_seconds: int.to_string(
      response.session_refresh_interval_seconds,
    ),
    session_previous_token_grace_seconds: int.to_string(
      response.session_previous_token_grace_seconds,
    ),
    session_heartbeat_interval_seconds: int.to_string(
      response.session_heartbeat_interval_seconds,
    ),
  )
}

pub fn request(
  fields: Fields,
) -> Result(auth_config_dto.UpsertAuthConfigRequest, String) {
  use login_token_max_age <- result.try(positive(
    fields.login_token_max_age,
    "Login token max age must be a positive integer.",
  ))
  use session_token_max_age <- result.try(positive(
    fields.session_token_max_age,
    "Session max lifetime must be a positive integer.",
  ))
  use session_idle_timeout_seconds <- result.try(positive(
    fields.session_idle_timeout_seconds,
    "Session idle timeout must be a positive integer.",
  ))
  use session_cookie_max_age <- result.try(positive(
    fields.session_cookie_max_age,
    "Session cookie max age must be a positive integer.",
  ))
  use session_refresh_interval_seconds <- result.try(positive(
    fields.session_refresh_interval_seconds,
    "Session rotation interval must be a positive integer.",
  ))
  use session_previous_token_grace_seconds <- result.try(positive(
    fields.session_previous_token_grace_seconds,
    "Previous token grace window must be a positive integer.",
  ))
  use session_heartbeat_interval_seconds <- result.try(positive(
    fields.session_heartbeat_interval_seconds,
    "Heartbeat cadence must be a positive integer.",
  ))
  Ok(auth_config_dto.UpsertAuthConfigRequest(
    login_token_max_age:,
    session_token_max_age:,
    session_idle_timeout_seconds:,
    session_cookie_max_age:,
    session_refresh_interval_seconds:,
    session_previous_token_grace_seconds:,
    session_heartbeat_interval_seconds:,
  ))
}

fn positive(value: String, message: String) -> Result(Int, String) {
  admin_format.parse_positive_int_with_error(value, message)
}
