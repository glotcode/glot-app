import glot_core/admin/snippet_dto
import glot_frontend/api/response as api_response

pub type Msg {
  SnippetsLoaded(api_response.Response(snippet_dto.ListSnippetsResponse))
  UsernameFilterChanged(String)
  SpamClassificationFilterChanged(String)
  ApplyFilterClicked
  ClearFilterClicked
  NextPageClicked
  PreviousPageClicked
}
