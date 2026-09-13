import gleam/list
import gleam/regexp
import gleam/string

/// Analysis only; callers retain the original snippet content.
pub fn text(value: String) -> String {
  value
  |> string.lowercase
  |> replace(
    "[\\x{00ad}\\x{034f}\\x{061c}\\x{180e}\\x{200b}-\\x{200f}\\x{202a}-\\x{202e}\\x{2060}-\\x{206f}\\x{feff}]",
    "",
  )
  |> replace("\\s+", " ")
  |> string.trim
}

pub fn refang(value: String) -> String {
  value
  |> string.replace("hxxps", "https")
  |> string.replace("hxxp", "http")
  |> replace("\\s*\\[\\s*\\.\\s*\\]\\s*|\\s*\\(\\s*\\.\\s*\\)\\s*", ".")
  |> replace("\\[\\s*:\\s*\\]", ":")
}

/// Underscores remain inside tokens so code identifiers do not become phrases.
pub fn words(value: String) -> List(String) {
  let assert Ok(pattern) = regexp.from_string("[\\p{L}\\p{N}_]+")
  regexp.scan(pattern, value)
  |> list.map(fn(match) { match.content })
}

pub fn replace(value: String, pattern: String, replacement: String) -> String {
  let assert Ok(pattern) = regexp.from_string(pattern)
  regexp.replace(pattern, value, replacement)
}
