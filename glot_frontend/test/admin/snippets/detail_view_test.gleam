import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/admin/snippet_dto
import glot_core/auth/user_dto
import glot_core/language
import glot_core/loadable
import glot_core/snippet/classification_explanation
import glot_core/snippet/classifier_provider
import glot_core/snippet/runnability
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import glot_frontend/admin/snippets/detail_model
import glot_frontend/admin/snippets/detail_view
import glot_frontend/request_generation
import lustre/element
import youid/uuid

fn fixture_model(explanation) {
  let assert Ok(snippet_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000001")
  let assert Ok(owner_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000002")
  let snippet =
    snippet_dto.SnippetDetailResponse(
      id: snippet_id,
      slug: "fixture-snippet",
      user: user_dto.UserResponse(id: owner_id, username: "fixture-owner"),
      title: "Fixture snippet",
      language: language.JavaScript,
      visibility: snippet_model.Public,
      stdin: "",
      run_instructions: option.None,
      files: [],
      spam_classification: spam_classification.ClassificationMetadata(
        explanation: explanation,
        decision: option.None,
        confidence: option.None,
        reason_code: option.None,
        classified_at: option.None,
        attempts: 0,
        last_error: option.None,
        failed_at: option.None,
      ),
      runnability: runnability.RunnabilityMetadata(
        is_runnable: option.Some(False),
        checked_at: option.Some(timestamp.from_unix_seconds(150)),
        attempts: 2,
        last_error: option.None,
        failed_at: option.None,
      ),
      created_at: timestamp.from_unix_seconds(100),
      updated_at: timestamp.from_unix_seconds(200),
    )
  let model =
    detail_model.Model(
      slug: snippet.slug,
      snippet: loadable.Loaded(snippet),
      pending_delete: option.None,
      classification_state: detail_model.ClassificationIdle,
      classification_error: option.None,
      classification_generation: request_generation.initial(),
      delete_state: detail_model.DeleteIdle,
      delete_generation: request_generation.initial(),
    )

  model
}

pub fn owner_name_and_id_link_to_the_admin_user_detail_page_test() {
  let model = fixture_model(option.None)
  let rendered = detail_view.view(model) |> element.to_document_string
  let owner_href = "href=\"/admin/users/00000000-0000-4000-8000-000000000002\""

  assert rendered |> string.split(owner_href) |> list.length == 4
  assert string.contains(rendered, ">fixture-owner</a>")
  assert string.contains(rendered, ">00000000-0000-4000-8000-000000000002</a>")
  assert string.contains(rendered, ">Run spam classification</button>")
  assert string.contains(rendered, ">Runnability</h3>")
  assert string.contains(rendered, ">Not runnable</")
}

pub fn local_explanations_show_score_signals_and_admin_neighbor_links_test() {
  let value =
    classification_explanation.Explanation(
      classifier_provider.Local,
      option.Some("local-v1"),
      option.Some(75),
      ["promotional_url", "contact_url", "multiple_urls"],
      [
        classification_explanation.Neighbor(
          "neighbor-id",
          "similar-snippet",
          timestamp.from_unix_seconds(100),
          0.95,
        ),
      ],
    )
  let rendered =
    fixture_model(option.Some(value))
    |> detail_view.view
    |> element.to_document_string
  assert string.contains(rendered, "local-v1")
  assert string.contains(rendered, "75 / 100")
  assert string.contains(rendered, "uncalibrated rule confidence")
  assert string.contains(rendered, "Promotional phrase with a URL (+30)")
  assert string.contains(rendered, "href=\"/admin/snippets/similar-snippet\"")
  let historical =
    fixture_model(option.None) |> detail_view.view |> element.to_document_string
  assert string.contains(historical, "Explanation unavailable")
  assert !string.contains(historical, "local-v1")
}
