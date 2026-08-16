import glot_core/admin/snippet_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  SnippetLoaded(api_response.Response(snippet_dto.GetSnippetResponse))
  ClassifyClicked
  ClassificationFinished(
    Generation(request_generation.Shared),
    api_response.Response(snippet_dto.GetSnippetResponse),
  )
  DeleteClicked
  DeleteCancelled
  DeleteDialogClosed
  DeleteConfirmed
  DeleteFinished(
    Generation(request_generation.Shared),
    api_response.Response(Nil),
  )
}
