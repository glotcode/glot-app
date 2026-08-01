import gleam/option
import glot_backend/logging/run_log/ports/store
import support/integration/adapter/state
import support/integration/adapter/unexpected
import support/integration/store/logging

pub fn defaults() -> store.Store {
  store.Store(
    create: fn(_) { unexpected.command("run_log.create") },
    list: fn(_) { unexpected.query("run_log.list") },
    get: fn(_) { unexpected.query("run_log.get") },
    delete_before: fn(_) { unexpected.command("run_log.delete_before") },
  )
}

pub fn new(test_state: state.State) -> store.Store {
  store.Store(
    create: fn(run_log) {
      state.update(test_state, fn(db) { logging.insert_run_log(db, run_log) })
      Ok(Nil)
    },
    list: fn(_) { Ok([]) },
    get: fn(_) { Ok(option.None) },
    delete_before: fn(before) {
      state.update(test_state, fn(db) {
        logging.delete_run_logs_before(db, before)
      })
      Ok(Nil)
    },
  )
}
