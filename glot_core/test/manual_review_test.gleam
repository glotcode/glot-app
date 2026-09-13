import gleam/json
import gleam/option
import gleam/time/timestamp
import glot_core/admin/spam_review_dto
import glot_core/admin_action
import glot_core/pagination_model
import glot_core/snippet/manual_review
import glot_core/snippet/spam_review_filter
import youid/uuid

pub fn manual_metadata_and_guarded_request_roundtrip_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000001")
  let time = timestamp.from_unix_seconds(100)
  let metadata =
    manual_review.ManualReview(
      option.Some(manual_review.NotSpam),
      option.Some(id),
      option.Some(time),
      7,
    )
  assert json.parse(
      json.to_string(manual_review.encode(metadata)),
      manual_review.decoder(),
    )
    == Ok(metadata)
  let request = spam_review_dto.SaveRequest("snippet", option.None, 7, time)
  assert json.parse(
      json.to_string(spam_review_dto.encode_save_request(request)),
      spam_review_dto.save_request_decoder(),
    )
    == Ok(request)
  let request =
    spam_review_dto.ListRequest(
      pagination_model.InitialPage(1),
      spam_review_filter.default(),
      option.Some("snippet"),
      False,
    )
  assert json.parse(
      json.to_string(spam_review_dto.encode_list_request(request)),
      spam_review_dto.list_request_decoder(),
    )
    == Ok(request)
}

pub fn invalid_manual_verdicts_and_versions_are_rejected_test() {
  let assert Error(_) = json.parse("\"allow\"", manual_review.verdict_decoder())
  let assert Error(_) = json.parse("-1", manual_review.version_decoder())
  assert admin_action.from_string("get_admin_spam_review")
    == option.Some(admin_action.GetAdminSpamReviewAction)
  assert admin_action.from_string("save_admin_manual_review")
    == option.Some(admin_action.SaveAdminManualReviewAction)
}
