import gleam/dynamic/decode

pub type Provider {
  External
  Local
}

pub fn to_string(provider: Provider) -> String {
  case provider {
    External -> "external"
    Local -> "local"
  }
}

pub fn from_string(value: String) -> Result(Provider, String) {
  case value {
    "external" -> Ok(External)
    "local" -> Ok(Local)
    _ -> Error("Invalid classifier provider: " <> value)
  }
}

pub fn decoder() -> decode.Decoder(Provider) {
  decode.then(decode.string, fn(value) {
    case from_string(value) {
      Ok(provider) -> decode.success(provider)
      Error(message) -> decode.failure(External, message)
    }
  })
}
