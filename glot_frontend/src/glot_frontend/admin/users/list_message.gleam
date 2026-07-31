import glot_core/admin/user_dto
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  UsersLoaded(
    Generation(request_generation.Shared),
    api_response.Response(user_dto.ListUsersResponse),
  )
  SearchFilterChanged(String)
  RoleFilterChanged(String)
  AccountStateFilterChanged(String)
  AccountTierFilterChanged(String)
  ApplyFilterClicked
  ClearFilterClicked
  NextPageClicked
  PreviousPageClicked
}
