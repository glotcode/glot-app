import glot_backend/snippet/adapter/postgres/read
import glot_backend/snippet/adapter/postgres/write
import glot_backend/snippet/ports/store as snippet_store
import glot_backend/system/database as db_helpers

pub fn new(db: db_helpers.Db) -> snippet_store.Store {
  snippet_store.Store(
    get_snippet_by_id: fn(id) { read.get_by_id(db, id) },
    get_snippet_by_slug: fn(slug) { read.get_by_slug(db, slug) },
    get_snippet_by_slug_for_update: fn(slug) {
      read.get_by_slug_for_update(db, slug)
    },
    get_admin_snippet_by_slug: fn(slug) { read.get_admin_by_slug(db, slug) },
    list_snippets: fn(filter, pagination) { read.list(db, filter, pagination) },
    list_admin_snippets: fn(username, pagination) {
      read.list_admin(db, username, pagination)
    },
    delete_snippet: fn(id) { write.delete(db, id) },
    delete_snippets_by_account_id: fn(account_id) {
      write.delete_by_account_id(db, account_id)
    },
    create_snippet: fn(snippet) { write.create(db, snippet) },
    update_snippet: fn(snippet) { write.update(db, snippet) },
  )
}
