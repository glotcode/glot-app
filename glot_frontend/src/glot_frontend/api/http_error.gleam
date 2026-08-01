import gleam/json

pub type Error {
  NetworkError
  BodyReadError
  JsonError(json.DecodeError)
  UnexpectedResponse(status: Int)
}
