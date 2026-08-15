import gleam/option
import glot_backend/snippet/ports/store
import support/integration/adapter/state
import support/integration/adapter/unexpected
import support/integration/store/snippet

pub fn defaults() -> store.Store {
  store.Store(
    get_snippet_by_id: fn(_) { unexpected.query("snippet.get_by_id") },
    get_snippet_by_slug: fn(_) { unexpected.query("snippet.get_by_slug") },
    get_snippet_by_slug_for_update: fn(_) {
      unexpected.query("snippet.get_by_slug_for_update")
    },
    get_admin_snippet_by_slug: fn(_) {
      unexpected.query("snippet.get_admin_by_slug")
    },
    list_snippets: fn(_, _) { unexpected.query("snippet.list") },
    list_admin_snippets: fn(_, _) { unexpected.query("snippet.list_admin") },
    delete_snippet: fn(_) { unexpected.command("snippet.delete") },
    delete_snippets_by_account_id: fn(_) {
      unexpected.command("snippet.delete_by_account_id")
    },
    create_snippet: fn(_) { unexpected.command("snippet.create") },
    update_snippet: fn(_) { unexpected.command("snippet.update") },
    get_newest_unclassified_snippet: fn() {
      unexpected.query("snippet.get_newest_unclassified")
    },
    store_spam_classification: fn(_, _, _) {
      unexpected.command("snippet.store_spam_classification")
    },
    store_spam_classification_failure: fn(_, _, _) {
      unexpected.command("snippet.store_spam_classification_failure")
    },
  )
}

pub fn new(test_state: state.State) -> store.Store {
  store.Store(
    get_snippet_by_id: fn(id) {
      Ok(snippet.find_by_id(state.get(test_state), id))
    },
    get_snippet_by_slug: fn(slug) {
      Ok(snippet.find_by_slug(state.get(test_state), slug))
    },
    get_snippet_by_slug_for_update: fn(slug) {
      Ok(snippet.find_by_slug(state.get(test_state), slug))
    },
    get_admin_snippet_by_slug: fn(slug) {
      Ok(snippet.find_by_slug(state.get(test_state), slug))
    },
    list_snippets: fn(filter, pagination) {
      Ok(snippet.list_snippets(state.get(test_state), filter, pagination))
    },
    list_admin_snippets: fn(_, _) { Ok([]) },
    delete_snippet: fn(id) {
      state.update(test_state, fn(db) { snippet.delete_snippet_by_id(db, id) })
      Ok(Nil)
    },
    delete_snippets_by_account_id: fn(account_id) {
      state.update(test_state, fn(db) {
        snippet.delete_snippets_by_account_id(db, account_id)
      })
      Ok(Nil)
    },
    create_snippet: fn(value) {
      state.update(test_state, fn(db) { snippet.insert_snippet(db, value) })
      Ok(Nil)
    },
    update_snippet: fn(value) {
      state.update(test_state, fn(db) { snippet.insert_snippet(db, value) })
      Ok(Nil)
    },
    get_newest_unclassified_snippet: fn() { Ok(option.None) },
    store_spam_classification: fn(_, _, _) { Ok(Nil) },
    store_spam_classification_failure: fn(_, _, _) { Ok(Nil) },
  )
}
