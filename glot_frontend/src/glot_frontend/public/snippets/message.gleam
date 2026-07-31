import glot_core/snippet/snippet_dto
import glot_frontend/api/response
import glot_frontend/public/snippets/model.{type Request}
import glot_frontend/request_generation.{type Generation}
import glot_frontend/ui/delayed_loading

pub type Msg {
  EnvironmentLoaded(Request, String)
  SnippetsLoaded(Request, response.Response(snippet_dto.ListSnippetsResponse))
  LoadingDelayElapsed(Request, Generation(delayed_loading.Stream))
}
