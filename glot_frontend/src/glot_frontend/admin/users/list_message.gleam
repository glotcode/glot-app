import glot_core/admin/user_dto
import glot_frontend/api/response as api_response

pub type Msg {
  UsersLoaded(api_response.Response(user_dto.ListUsersResponse))
  SearchFilterChanged(String)
  RoleFilterChanged(String)
  AccountStateFilterChanged(String)
  AccountTierFilterChanged(String)
  ApplyFilterClicked
  ClearFilterClicked
  NextPageClicked
  PreviousPageClicked
}
