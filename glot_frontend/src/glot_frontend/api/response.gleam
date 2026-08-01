import glot_frontend/api/http_error
import youid/uuid

pub type Error {
  Error(code: String, message: String, request_id: uuid.Uuid)
}

pub type Response(a) {
  Success(data: a)
  ApiFailure(error: Error)
  HttpFailure(error: http_error.Error)
}

pub fn error_message(error: Error) -> String {
  let message = case error.code {
    "read_only_mode_enabled" ->
      error.message <> " Changes are temporarily disabled."
    "maintenance_mode_enabled" ->
      error.message <> " Most public actions are temporarily unavailable."
    _ -> error.message
  }

  message <> " Request ID: " <> uuid.to_string(error.request_id)
}

pub fn map(response: Response(a), transform: fn(a) -> b) -> Response(b) {
  case response {
    Success(data) -> Success(transform(data))
    ApiFailure(error) -> ApiFailure(error)
    HttpFailure(error) -> HttpFailure(error)
  }
}

pub fn user_message(
  response: Response(a),
  http_failure_message: String,
) -> String {
  case response {
    ApiFailure(error) -> error_message(error)
    HttpFailure(_) -> http_failure_message
    Success(_) -> ""
  }
}
