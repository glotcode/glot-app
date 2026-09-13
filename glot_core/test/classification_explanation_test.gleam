import gleam/json
import gleam/option
import gleam/time/timestamp
import glot_core/snippet/classification_explanation
import glot_core/snippet/classifier_provider

pub fn local_explanation_round_trip_test() {
  let explanation =
    classification_explanation.Explanation(
      classifier_provider.Local,
      option.Some("local-v1"),
      option.Some(75),
      ["promotional_url", "contact_url", "multiple_urls"],
      [
        classification_explanation.Neighbor(
          "id",
          "slug",
          timestamp.from_unix_seconds(100),
          0.95,
        ),
      ],
    )
  assert explanation
    |> classification_explanation.encode
    |> json.to_string
    |> json.parse(classification_explanation.decoder())
    == Ok(explanation)
}

pub fn external_provenance_does_not_invent_local_scores_test() {
  let explanation =
    classification_explanation.Explanation(
      classifier_provider.External,
      option.None,
      option.None,
      [],
      [],
    )
  assert explanation
    |> classification_explanation.encode
    |> json.to_string
    |> json.parse(classification_explanation.decoder())
    == Ok(explanation)
}
