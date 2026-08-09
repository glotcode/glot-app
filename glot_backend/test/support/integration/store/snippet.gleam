import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/order
import gleam/string
import glot_core/pagination_model
import glot_core/snippet/snippet_model
import support/integration/model
import support/integration/store/common
import youid/uuid

pub fn find_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> option.Option(snippet_model.HydratedSnippet) {
  case dict.get(db.snippets, common.uuid_key(id)) {
    Ok(snippet) -> hydrate(db, snippet)
    Error(_) -> option.None
  }
}

pub fn find_by_slug(
  db: model.TestState,
  slug: String,
) -> option.Option(snippet_model.HydratedSnippet) {
  db.snippets
  |> dict.values
  |> list.find(fn(snippet) { snippet.slug == slug })
  |> option.from_result
  |> option.then(hydrate(db, _))
}

pub fn list_snippets(
  db: model.TestState,
  filter: snippet_model.ListSnippetsFilter,
  pagination: pagination_model.CursorPagination,
) -> List(snippet_model.HydratedSnippet) {
  let snippets =
    db.snippets
    |> dict.values
    |> list.filter(fn(snippet) { matches_filter(db, snippet, filter) })
    |> list.sort(fn(left, right) {
      reverse_order(string.compare(left.slug, right.slug))
    })
    |> list.filter_map(fn(snippet) {
      hydrate(db, snippet) |> option.to_result(Nil)
    })

  case pagination {
    pagination_model.InitialPage(limit) -> list.take(snippets, limit)
    pagination_model.AfterPage(cursor, limit) ->
      snippets
      |> list.filter(fn(snippet) {
        string.compare(
          snippet.identity.slug,
          pagination_model.to_string(cursor),
        )
        == order.Lt
      })
      |> list.take(limit)
    pagination_model.BeforePage(cursor, limit) ->
      snippets
      |> list.filter(fn(snippet) {
        string.compare(
          snippet.identity.slug,
          pagination_model.to_string(cursor),
        )
        == order.Gt
      })
      |> list.reverse
      |> list.take(limit)
      |> list.reverse
  }
}

pub fn insert_snippet(
  db: model.TestState,
  snippet: snippet_model.Snippet,
) -> model.TestState {
  model.TestState(
    ..db,
    snippets: dict.insert(db.snippets, common.uuid_key(snippet.id), snippet),
  )
}

pub fn delete_snippet_by_id(
  db: model.TestState,
  id: uuid.Uuid,
) -> model.TestState {
  model.TestState(..db, snippets: dict.delete(db.snippets, common.uuid_key(id)))
}

pub fn delete_snippets_by_account_id(
  db: model.TestState,
  account_id: uuid.Uuid,
) -> model.TestState {
  model.TestState(
    ..db,
    snippets: remove_snippets_by_account_id(db, account_id),
    deletion_steps: ["delete_snippets_by_account_id", ..db.deletion_steps],
  )
}

fn remove_snippets_by_account_id(
  db: model.TestState,
  account_id: uuid.Uuid,
) -> Dict(String, snippet_model.Snippet) {
  db.snippets
  |> dict.to_list
  |> list.filter(fn(entry) {
    let #(_, snippet) = entry
    case dict.get(db.users, common.uuid_key(snippet.user_id)) {
      Ok(user) -> user.account_id != account_id
      Error(_) -> True
    }
  })
  |> dict.from_list
}

fn hydrate(
  db: model.TestState,
  snippet: snippet_model.Snippet,
) -> option.Option(snippet_model.HydratedSnippet) {
  case dict.get(db.users, common.uuid_key(snippet.user_id)) {
    Ok(user) ->
      option.Some(snippet_model.HydratedSnippet(identity: snippet, user: user))
    Error(_) -> option.None
  }
}

fn matches_filter(
  db: model.TestState,
  snippet: snippet_model.Snippet,
  filter: snippet_model.ListSnippetsFilter,
) -> Bool {
  case dict.get(db.users, common.uuid_key(snippet.user_id)) {
    Error(_) -> False
    Ok(user) ->
      matches_optional_filter(filter.visibilities, snippet.visibility)
      && matches_optional_filter(filter.usernames, user.username)
      && matches_optional_filter(filter.languages, snippet.language)
      && matches_optional_filter(filter.user_ids, user.id)
      && !list.contains(filter.skip_user_ids, user.id)
      && !list.contains(
        list.map(filter.excluded_titles, string.lowercase),
        string.lowercase(snippet.title),
      )
      && !list.contains(filter.excluded_languages, snippet.language)
  }
}

fn matches_optional_filter(values: List(a), value: a) -> Bool {
  list.is_empty(values) || list.contains(values, value)
}

fn reverse_order(value: order.Order) -> order.Order {
  case value {
    order.Lt -> order.Gt
    order.Eq -> order.Eq
    order.Gt -> order.Lt
  }
}
