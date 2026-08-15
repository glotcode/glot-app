import gleam/option
import gleam/result
import glot_backend/app_config/decoder/value
import glot_backend/app_config/model/entry.{type AppConfigEntry}
import glot_backend/spam_classifier/model/config

pub fn spam_classifier(
  current: option.Option(config.Config),
  entry: AppConfigEntry,
) -> Result(option.Option(config.Config), String) {
  let base = option.unwrap(current, config.Config(base_url: "", auth_token: ""))
  case entry.key {
    "base_url" -> {
      use decoded <- result.try(value.string("spam_classifier", entry))
      Ok(option.Some(config.Config(..base, base_url: decoded)))
    }
    "auth_token" -> {
      use decoded <- result.try(value.string("spam_classifier", entry))
      Ok(option.Some(config.Config(..base, auth_token: decoded)))
    }
    _ -> Ok(current)
  }
}
