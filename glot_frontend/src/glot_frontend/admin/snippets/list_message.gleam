import glot_core/admin/snippet_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  SnippetsLoaded(
    Generation(request_generation.Shared),
    api_response.Response(snippet_dto.ListSnippetsResponse),
  )
  UsernameFilterChanged(String)
  ApplyFilterClicked
  ClearFilterClicked
  NextPageClicked
  PreviousPageClicked
}
