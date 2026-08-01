import gleam/option
import glot_core/admin/snippet_dto
import glot_core/loadable
import glot_frontend/request_generation.{type Generation}

pub type Model {
  Model(
    slug: String,
    snippet: loadable.Loadable(snippet_dto.SnippetDetailResponse),
    pending_delete: option.Option(snippet_dto.SnippetDetailResponse),
    delete_state: DeleteState,
    delete_generation: Generation(request_generation.Shared),
  )
}

pub type DeleteState {
  DeleteIdle
  Deleting
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.snippet)
}
