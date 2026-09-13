import gleam/option
import glot_core/admin/spam_review_dto.{type ReviewSnippet}
import glot_core/pagination_model.{type CursorPage}
import glot_core/snippet/manual_review.{type ManualReview, type Verdict}
import glot_frontend/admin/spam_review/query.{type Field}
import glot_frontend/api/response.{type Response}

pub type Msg {
  Loaded(Int, Response(CursorPage(ReviewSnippet)))
  FieldChanged(Field, String)
  Apply
  Clear
  Previous
  Next
  Reload
  Save(option.Option(Verdict))
  Saved(ReviewSnippet, Response(ManualReview))
  Undo
  Undone(Response(ManualReview))
}
