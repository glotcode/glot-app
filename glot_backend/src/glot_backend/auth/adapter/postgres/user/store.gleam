import glot_backend/auth/adapter/postgres/user/read
import glot_backend/auth/adapter/postgres/user/write
import glot_backend/auth/ports/user_store
import glot_backend/system/database as db_helpers

pub fn new(db: db_helpers.Db) -> user_store.UserStore {
  user_store.UserStore(
    get_by_email: fn(is_email, email) { read.get_by_email(db, is_email, email) },
    get_by_id: fn(is_email, id) { read.get_by_id(db, is_email, id) },
    get_by_id_for_update: fn(is_email, id) {
      read.get_by_id_for_update(db, is_email, id)
    },
    list: fn(is_email, pagination, filters) {
      read.list(db, is_email, pagination, filters)
    },
    create: fn(user) { write.create(db, user) },
    update_last_login: fn(id, timestamp) {
      write.update_last_login(db, id, timestamp)
    },
    update_email: fn(id, email, timestamp) {
      write.update_email(db, id, email, timestamp)
    },
    update_username: fn(id, username, timestamp) {
      write.update_username(db, id, username, timestamp)
    },
    update_role: fn(id, role, timestamp) {
      write.update_role(db, id, role, timestamp)
    },
    lock_email: fn(email) { write.lock_email(db, email) },
    delete_by_account_id: fn(id) { write.delete_by_account_id(db, id) },
  )
}
