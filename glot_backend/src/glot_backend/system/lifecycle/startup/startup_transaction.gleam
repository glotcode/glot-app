import pog

/// Run startup SQL in one transaction that may take longer than a request.
///
/// `pog.transaction` checks its connection out of the pool with pgo's default
/// 5 second hold deadline. When the deadline fires, the pool disconnects the
/// socket mid-statement, so a long migration failed with `QueryTimeout` while
/// Postgres kept running it, and the startup retry queued another copy behind
/// it. This runs through pgo's own transaction with an unlimited checkout.
/// Queries issued on `db` inside the callback go to that transaction's
/// connection. Returning `Error` rolls the transaction back.
@external(erlang, "startup_transaction_ffi", "run")
pub fn run(
  db: pog.Connection,
  callback: fn() -> Result(t, String),
) -> Result(t, String)
