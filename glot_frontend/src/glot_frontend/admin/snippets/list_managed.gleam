import gleam/option
import gleam/string
import glot_core/admin/snippet_dto
import glot_core/loadable
import glot_core/pagination_model
import glot_core/route
import glot_core/snippet/spam_classification
import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/list_query
import glot_frontend/admin/snippets/list_message.{
  ApplyFilterClicked, ClearFilterClicked, NextPageClicked, PreviousPageClicked,
  SnippetsLoaded, SpamClassificationFilterChanged, UsernameFilterChanged,
}
import glot_frontend/admin/snippets/list_model.{Model}
import glot_frontend/admin/ui/cursor_page as admin_cursor_page

pub type Model =
  list_model.Model

pub type Msg =
  list_message.Msg

const page_limit = 25

pub fn init(
  raw_query: option.Option(String),
) -> #(Model, admin_effect.Command(Msg)) {
  let query = list_query.parse(raw_query)
  #(
    Model(
      page: loadable.NotLoaded,
      username_filter: list_query.value_or(query, "username", ""),
      spam_classification_filter: list_query.value_or(
        query,
        "classification",
        "",
      ),
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
    SnippetsLoaded(result) ->
      case result {
        _ -> #(
          Model(
            ..model,
            page: admin_cursor_page.page_from_response(
              result,
              fn(response) { response.page },
              "Could not load snippets.",
            ),
          ),
          admin_effect.none(),
        )
      }

    UsernameFilterChanged(value) -> #(
      Model(..model, username_filter: value),
      admin_effect.none(),
    )

    SpamClassificationFilterChanged(value) -> #(
      Model(..model, spam_classification_filter: value),
      admin_effect.none(),
    )

    ApplyFilterClicked -> navigate(model, list_query.initial(page_limit))

    ClearFilterClicked ->
      case
        model.username_filter == "" && model.spam_classification_filter == ""
      {
        True -> #(model, admin_effect.none())
        False ->
          navigate(
            Model(..model, username_filter: "", spam_classification_filter: ""),
            list_query.initial(page_limit),
          )
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
        route.AdminSnippets(query: list_query.encode(
          [
            #("username", option.Some(model.username_filter)),
            #("classification", option.Some(model.spam_classification_filter)),
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
    admin_effect.get_admin_snippets(
      snippet_dto.ListSnippetsRequest(
        pagination: pagination,
        username: filter_username(model.username_filter),
        spam_classification: spam_classification_filter(
          model.spam_classification_filter,
        ),
      ),
      SnippetsLoaded,
    ),
  )
}

fn spam_classification_filter(value: String) {
  case value {
    "pass" ->
      option.Some(spam_classification.Classified(spam_classification.Allow))
    "review" ->
      option.Some(spam_classification.Classified(spam_classification.Review))
    "block" ->
      option.Some(spam_classification.Classified(spam_classification.Block))
    "unclassified" -> option.Some(spam_classification.Unclassified)
    _ -> option.None
  }
}

fn filter_username(value: String) -> option.Option(String) {
  case string.trim(value) {
    "" -> option.None
    username -> option.Some(username)
  }
}
