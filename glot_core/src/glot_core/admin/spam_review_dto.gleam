import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/admin/snippet_dto.{type SnippetDetailResponse}
import glot_core/helpers/timestamp_helpers
import glot_core/pagination_model.{type CursorPage, type CursorPagination}
import glot_core/snippet/manual_review.{type ManualReview, type Verdict}
import glot_core/snippet/spam_review_filter.{type SpamReviewFilter}

pub type ReviewSnippet {
  ReviewSnippet(snippet: SnippetDetailResponse, manual_review: ManualReview)
}

pub type ListRequest {
  ListRequest(
    pagination: CursorPagination,
    filter: SpamReviewFilter,
    focus: option.Option(String),
    inclusive: Bool,
  )
}

pub type SaveRequest {
  SaveRequest(
    slug: String,
    verdict: option.Option(Verdict),
    expected_version: Int,
    revision: Timestamp,
  )
}

pub fn list_request_decoder() -> decode.Decoder(ListRequest) {
  use pagination <- decode.then(pagination_model.request_decoder())
  use filter <- decode.field("filter", spam_review_filter.decoder())
  use focus <- decode.optional_field(
    "focus",
    option.None,
    decode.optional(decode.string),
  )
  use inclusive <- decode.optional_field("inclusive", False, decode.bool)
  decode.success(ListRequest(pagination:, filter:, focus:, inclusive:))
}

pub fn encode_list_request(request: ListRequest) -> json.Json {
  json.object(
    list.append(pagination_model.encode_request_fields(request.pagination), [
      #("filter", spam_review_filter.encode(request.filter)),
      #("focus", json.nullable(request.focus, json.string)),
      #("inclusive", json.bool(request.inclusive)),
    ]),
  )
}

pub fn snippet_decoder() -> decode.Decoder(ReviewSnippet) {
  use snippet <- decode.field("snippet", snippet_dto.snippet_detail_decoder())
  use manual_review <- decode.field("manualReview", manual_review.decoder())
  decode.success(ReviewSnippet(snippet:, manual_review:))
}

pub fn encode_snippet(value: ReviewSnippet) -> json.Json {
  json.object([
    #("snippet", snippet_dto.encode_snippet_detail(value.snippet)),
    #("manualReview", manual_review.encode(value.manual_review)),
  ])
}

pub fn list_response_decoder() -> decode.Decoder(CursorPage(ReviewSnippet)) {
  pagination_model.page_decoder("snippets", snippet_decoder())
}

pub fn encode_list_response(page: CursorPage(ReviewSnippet)) -> json.Json {
  pagination_model.encode_page(page, "snippets", encode_snippet)
}

pub fn save_request_decoder() -> decode.Decoder(SaveRequest) {
  use slug <- decode.field("slug", decode.string)
  use verdict <- decode.field(
    "verdict",
    decode.optional(manual_review.verdict_decoder()),
  )
  use expected_version <- decode.field(
    "expectedVersion",
    manual_review.version_decoder(),
  )
  use revision <- decode.field("revision", timestamp_helpers.decoder())
  decode.success(SaveRequest(slug:, verdict:, expected_version:, revision:))
}

pub fn encode_save_request(request: SaveRequest) -> json.Json {
  json.object([
    #("slug", json.string(request.slug)),
    #(
      "verdict",
      json.nullable(request.verdict, fn(value) {
        json.string(manual_review.to_string(value))
      }),
    ),
    #("expectedVersion", json.int(request.expected_version)),
    #("revision", timestamp_helpers.encode(request.revision)),
  ])
}
