import gleam/dict.{type Dict}
import gleam/list
import gleam/option
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
