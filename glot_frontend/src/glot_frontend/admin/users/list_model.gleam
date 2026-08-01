import glot_core/admin/user_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/cursor_request

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(user_dto.UserSummaryResponse),
    ),
    search_filter: String,
    role_filter: String,
    account_state_filter: String,
    account_tier_filter: String,
    request_generation: cursor_request.State,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
