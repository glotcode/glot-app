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
import glot_frontend/api/response
import youid/uuid

import gleam/string
import glot_core/admin/spam_review_dto
import glot_core/pagination_model
import glot_core/route
import glot_core/snippet/manual_review
import glot_core/snippet/spam_review_filter
import glot_frontend/admin/router_managed
import glot_frontend/admin/router_message
import glot_frontend/admin/router_state
import glot_frontend/admin/spam_review/managed
import glot_frontend/admin/spam_review/message
import glot_frontend/admin/spam_review/query

pub fn defaults_and_filter_validation_test() {
  assert query.validate(query.parse(option.None))
    == Ok(spam_review_filter.default())
  assert query.validate(query.all()) == Ok(spam_review_filter.all())
  let all = query.all()
  let assert Error(_) = query.validate(query.Draft(..all, minimum: "-1"))
  let assert Error(_) = query.validate(query.Draft(..all, maximum: "101"))
  let assert Error(_) =
    query.validate(query.Draft(..all, minimum: "50", maximum: "49"))
  let assert Ok(filter) =
    query.validate(query.Draft(..all, minimum: "0", maximum: "100"))
  assert filter.confidence_min == option.Some(0)
  assert filter.confidence_max == option.Some(100)
}

pub fn field_messages_preserve_other_pending_changes_test() {
  let #(initial, _) = managed.init(option.None)
  let #(first, _) =
    managed.update(initial, message.FieldChanged(query.Minimum, "75"))
  let #(second, _) =
    managed.update(first, message.FieldChanged(query.Maximum, "80"))
  assert second.draft.minimum == "75"
  assert second.draft.maximum == "80"
}

pub fn same_route_reload_ignores_obsolete_responses_test() {
  let #(initial, _) = managed.init(option.None)
  let assert #(loading, command.Content(content.GetSpamReview(_, first))) =
    managed.ensure_loaded(initial)
  let assert #(reloading, command.Content(content.GetSpamReview(_, second))) =
    managed.update(loading, message.Reload)
  let #(obsolete, _) =
    managed.update(reloading, first(response.Success(page())))
  assert obsolete == reloading
  let #(loaded, _) = managed.update(obsolete, second(response.Success(page())))
  assert loaded.page == loadable.Loaded(page())
}

pub fn save_is_guarded_and_advances_only_on_success_test() {
  let loaded = loaded()
  let assert #(
    saving,
    command.Content(content.SaveManualReview(request, complete)),
  ) = managed.update(loaded, message.Save(option.Some(manual_review.Spam)))
  assert request.expected_version == 0
  assert request.revision == fixture_snippet().updated_at
  let #(duplicate, duplicate_command) =
    managed.update(saving, message.Save(option.Some(manual_review.NotSpam)))
  assert duplicate == saving
  assert duplicate_command == command.None
  let error =
    response.ApiFailure(response.Error(
      "fixture",
      "Retry me",
      fixture_snippet().id,
    ))
  let #(failed, fail_command) = managed.update(saving, complete(error))
  assert failed.page == loaded.page
  assert !failed.saving
  assert fail_command == command.None
  let assert #(saving, command.Content(content.SaveManualReview(_, complete))) =
    managed.update(failed, message.Save(option.Some(manual_review.Spam)))
  let saved =
    manual_review.ManualReview(
      ..manual_review.empty(),
      verdict: option.Some(manual_review.Spam),
      version: 1,
    )
  let assert #(
    advanced,
    command.Navigate(route.Admin(route.AdminSpamReview(option.Some(url)))),
  ) = managed.update(saving, complete(response.Success(saved)))
  assert string.contains(url, "after=fixture-snippet")
  let assert option.Some(undo) = advanced.undo
  assert undo.item.manual_review.verdict == option.None
  assert undo.saved_version == 1
  let #(routed, _) =
    router_managed.init_from(
      router_state.new(router_state.AdminSpamReviewPage(advanced)),
      route.AdminSpamReview(option.Some(url)),
      True,
    )
  let assert router_state.AdminSpamReviewPage(next) = router_state.page(routed)
  assert next.undo == advanced.undo
  let assert #(_, command.Content(content.SaveManualReview(undo_request, _))) =
    managed.update(next, message.Undo)
  assert undo_request.verdict == option.None
  assert undo_request.expected_version == 1
  assert undo_request.revision == request.revision
}

pub fn stale_route_messages_do_not_update_other_pages_test() {
  let #(review, _) =
    router_managed.init(route.AdminSpamReview(option.None), True)
  let #(directory, _) =
    router_managed.init_from(review, route.AdminSnippets(option.None), True)
  let #(unchanged, _) =
    router_managed.update(
      directory,
      router_message.AdminSpamReviewPageMsg(message.Loaded(
        1,
        response.Success(page()),
      )),
    )
  assert unchanged == directory
}

fn loaded() {
  let #(initial, _) = managed.init(option.None)
  let assert #(loading, command.Content(content.GetSpamReview(_, complete))) =
    managed.ensure_loaded(initial)
  let #(loaded, _) = managed.update(loading, complete(response.Success(page())))
  loaded
}

fn page() {
  pagination_model.InitialCursorPage(
    [spam_review_dto.ReviewSnippet(fixture_snippet(), manual_review.empty())],
    option.None,
  )
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
      explanation: option.None,
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
