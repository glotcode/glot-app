import gleam/list
import gleam/option.{type Option}
import gleam/string

pub type BuildInfo {
  BuildInfo(commit: String)
}

pub const repository_url = "https://github.com/glotcode/glot-app"

const injected_commit = "__GLOT_BUILD_COMMIT__"

pub fn current() -> Option(BuildInfo) {
  from_commit(injected_commit)
}

pub fn from_commit(commit: String) -> Option(BuildInfo) {
  case is_commit(commit) {
    True -> option.Some(BuildInfo(commit: commit))
    False -> option.None
  }
}

pub fn short_commit(build_info: BuildInfo) -> String {
  string.slice(build_info.commit, at_index: 0, length: 7)
}

pub fn commit_url(build_info: BuildInfo) -> String {
  repository_url <> "/commit/" <> build_info.commit
}

fn is_commit(value: String) -> Bool {
  string.length(value) == 40
  && value
  |> string.to_graphemes
  |> list.all(fn(character) { string.contains("0123456789abcdef", character) })
}
