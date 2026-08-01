import glot_core/admin/user_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_frontend/admin/list_query

pub type Model {
  Model(
    page: loadable.Loadable(
      pagination_model.CursorPage(user_dto.UserSummaryResponse),
    ),
    search_filter: String,
    role_filter: String,
    account_state_filter: String,
    account_tier_filter: String,
    query: list_query.Query,
  )
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.page)
}
