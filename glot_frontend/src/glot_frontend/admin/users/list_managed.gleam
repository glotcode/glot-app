import gleam/option
import glot_core/admin/user_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/list_query
import glot_frontend/admin/ui/cursor_page as admin_cursor_page
import glot_frontend/admin/users/list_filter
import glot_frontend/admin/users/list_message.{
  AccountStateFilterChanged, AccountTierFilterChanged, ApplyFilterClicked,
  ClearFilterClicked, NextPageClicked, PreviousPageClicked, RoleFilterChanged,
  SearchFilterChanged, UsersLoaded,
}
import glot_frontend/admin/users/list_model.{Model}

const page_limit = 25

pub fn init(
  raw_query: option.Option(String),
) -> #(Model, admin_effect.Command(Msg)) {
  let query = list_query.parse(raw_query)
  #(
    Model(
      page: loadable.NotLoaded,
      search_filter: list_query.value_or(query, "search", ""),
      role_filter: list_query.value_or(query, "role", ""),
      account_state_filter: list_query.value_or(query, "state", ""),
      account_tier_filter: list_query.value_or(query, "tier", ""),
      query: query,
    ),
    admin_effect.none(),
  )
}

pub fn ensure_loaded(model: Model) -> #(Model, admin_effect.Command(Msg)) {
  case model.page {
    loadable.NotLoaded ->
      load_page(
        Model(..model, page: loadable.Loading),
        list_query.pagination(model.query, page_limit),
      )
    loadable.Loading | loadable.Loaded(_) | loadable.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, admin_effect.Command(Msg)) {
  case msg {
    UsersLoaded(result) ->
      case result {
        _ -> #(
          Model(
            ..model,
            page: admin_cursor_page.page_from_response(
              result,
              fn(response) { response.page },
              "Could not load users.",
            ),
          ),
          admin_effect.none(),
        )
      }

    SearchFilterChanged(value) -> #(
      Model(..model, search_filter: value),
      admin_effect.none(),
    )

    RoleFilterChanged(value) -> #(
      Model(..model, role_filter: value),
      admin_effect.none(),
    )

    AccountStateFilterChanged(value) -> #(
      Model(..model, account_state_filter: value),
      admin_effect.none(),
    )

    AccountTierFilterChanged(value) -> #(
      Model(..model, account_tier_filter: value),
      admin_effect.none(),
    )

    ApplyFilterClicked -> navigate(model, list_query.initial(page_limit))

    ClearFilterClicked ->
      case list_filter.has_filters(model) {
        True ->
          navigate(
            Model(
              ..model,
              search_filter: "",
              role_filter: "",
              account_state_filter: "",
              account_tier_filter: "",
            ),
            list_query.initial(page_limit),
          )
        False -> #(model, admin_effect.none())
      }

    NextPageClicked ->
      case admin_cursor_page.next_pagination(model.page, page_limit) {
        option.Some(pagination) -> navigate(model, pagination)
        option.None -> #(model, admin_effect.none())
      }

    PreviousPageClicked ->
      case admin_cursor_page.previous_pagination(model.page, page_limit) {
        option.Some(pagination) -> navigate(model, pagination)
        option.None -> #(model, admin_effect.none())
      }
  }
}

fn navigate(model: Model, pagination: pagination_model.CursorPagination) {
  #(
    model,
    admin_effect.Navigate(
      route.Admin(
        route.AdminUsers(query: list_query.encode(
          [
            #("search", option.Some(model.search_filter)),
            #("role", option.Some(model.role_filter)),
            #("state", option.Some(model.account_state_filter)),
            #("tier", option.Some(model.account_tier_filter)),
          ],
          pagination,
        )),
      ),
    ),
  )
}

fn load_page(
  model: Model,
  pagination: pagination_model.CursorPagination,
) -> #(Model, admin_effect.Command(Msg)) {
  #(
    model,
    admin_effect.get_admin_users(
      user_dto.ListUsersRequest(
        pagination: pagination,
        email: list_filter.email(model.search_filter),
        username: list_filter.username(model.search_filter),
        id: list_filter.user_id(model.search_filter),
        role: list_filter.role(model.role_filter),
        account_state: list_filter.account_state(model.account_state_filter),
        account_tier: list_filter.account_tier(model.account_tier_filter),
      ),
      UsersLoaded,
    ),
  )
}

pub type Model =
  list_model.Model

pub type Msg =
  list_message.Msg
