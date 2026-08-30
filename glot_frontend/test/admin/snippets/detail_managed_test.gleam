import gleam/option
import gleam/time/timestamp
import glot_core/admin/snippet_dto
import glot_core/auth/user_dto
import glot_core/language
import glot_core/loadable
import glot_core/snippet/runnability
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import glot_frontend/admin/command
import glot_frontend/admin/effect/content
import glot_frontend/admin/snippets/detail_managed
import glot_frontend/admin/snippets/detail_message
import glot_frontend/admin/snippets/detail_model
import glot_frontend/api/response
import youid/uuid

pub fn classification_completion_replaces_existing_classification_test() {
  let snippet = fixture_snippet()
  let #(initial, _) = detail_managed.init(snippet.slug)
  let #(loaded, _) =
    detail_managed.update(
      initial,
      detail_message.SnippetLoaded(
        response.Success(snippet_dto.GetSnippetResponse(snippet: snippet)),
      ),
    )

  let #(classifying, classify_command) =
    detail_managed.update(loaded, detail_message.ClassifyClicked)
  assert classifying.classification_state == detail_model.Classifying
  let assert command.Content(content.ClassifySnippet(request, complete)) =
    classify_command
  assert request.slug == snippet.slug

  let replacement =
    snippet_dto.SnippetDetailResponse(
      ..snippet,
      spam_classification: spam_classification.ClassificationMetadata(
        decision: option.Some(spam_classification.Block),
        confidence: option.Some(98),
        reason_code: option.Some(spam_classification.LinkSpam),
        classified_at: option.Some(timestamp.from_unix_seconds(300)),
        attempts: 4,
        last_error: option.None,
        failed_at: option.None,
      ),
    )
  let #(updated, _) =
    detail_managed.update(
      classifying,
      complete(
        response.Success(snippet_dto.GetSnippetResponse(snippet: replacement)),
      ),
    )

  assert updated.snippet == loadable.Loaded(replacement)
  assert updated.classification_state == detail_model.ClassificationIdle
  assert updated.classification_error == option.None
}

fn fixture_snippet() -> snippet_dto.SnippetDetailResponse {
  let assert Ok(snippet_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000001")
  let assert Ok(owner_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000002")
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
      decision: option.Some(spam_classification.Allow),
      confidence: option.Some(70),
      reason_code: option.Some(spam_classification.None),
      classified_at: option.Some(timestamp.from_unix_seconds(100)),
      attempts: 3,
      last_error: option.None,
      failed_at: option.None,
    ),
    runnability: runnability.RunnabilityMetadata(
      is_runnable: option.Some(True),
      checked_at: option.Some(timestamp.from_unix_seconds(150)),
      attempts: 1,
      last_error: option.None,
      failed_at: option.None,
    ),
    created_at: timestamp.from_unix_seconds(100),
    updated_at: timestamp.from_unix_seconds(200),
  )
}
