import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import glot_core/helpers/timestamp_helpers
import glot_core/snippet/classifier_provider.{type Provider}

pub type Explanation {
  Explanation(
    provider: Provider,
    version: Option(String),
    score: Option(Int),
    signals: List(String),
    neighbors: List(Neighbor),
  )
}

pub type Neighbor {
  Neighbor(id: String, slug: String, revision: Timestamp, similarity: Float)
}

pub fn encode(value: Explanation) -> json.Json {
  json.object([
    #("provider", json.string(classifier_provider.to_string(value.provider))),
    #("version", json.nullable(value.version, json.string)),
    #("score", json.nullable(value.score, json.int)),
    #("signals", json.array(value.signals, json.string)),
    #(
      "neighbors",
      json.array(value.neighbors, fn(neighbor) {
        json.object([
          #("id", json.string(neighbor.id)),
          #("slug", json.string(neighbor.slug)),
          #("revision", timestamp_helpers.encode(neighbor.revision)),
          #("similarity", json.float(neighbor.similarity)),
        ])
      }),
    ),
  ])
}

pub fn decoder() -> decode.Decoder(Explanation) {
  use provider <- decode.field("provider", classifier_provider.decoder())
  use version <- decode.field("version", decode.optional(decode.string))
  use score <- decode.field("score", decode.optional(decode.int))
  use signals <- decode.field("signals", decode.list(decode.string))
  use neighbors <- decode.field("neighbors", decode.list(neighbor_decoder()))
  decode.success(Explanation(provider:, version:, score:, signals:, neighbors:))
}

fn neighbor_decoder() -> decode.Decoder(Neighbor) {
  use id <- decode.field("id", decode.string)
  use slug <- decode.field("slug", decode.string)
  use revision <- decode.field("revision", timestamp_helpers.decoder())
  use similarity <- decode.field("similarity", decode.float)
  decode.success(Neighbor(id:, slug:, revision:, similarity:))
}
