import gleam/option
import glot_backend/job/ports
import glot_backend/job/ports/job_store
import glot_backend/job/ports/log_store
import glot_backend/job/ports/periodic_store
import glot_backend/job/ports/type_policy_store
import glot_core/job/job_model
import support/integration/adapter/state
import support/integration/adapter/unexpected
import support/integration/store/job

pub fn defaults() -> ports.Ports {
  ports.Ports(
    jobs: job_store.JobStore(
      list_jobs: fn(_, _) { unexpected.query("job.list") },
      summarize_jobs: fn(_, _) { unexpected.query("job.summarize") },
      get_next_job: fn(_, _, _) { unexpected.query("job.get_next") },
      get_expired_running_job: fn(_, _, _) {
        unexpected.query("job.get_expired_running")
      },
      get_job_by_id: fn(_) { unexpected.query("job.get_by_id") },
      create_job: fn(_) { unexpected.command("job.create") },
      update_job: fn(_) { unexpected.command("job.update") },
      claim_queue_slot: fn(_, _, _) { unexpected.query("job.claim_slot") },
      release_queue_slot: fn(_, _) { unexpected.command("job.release_slot") },
      delete_job: fn(_) { unexpected.command("job.delete") },
      delete_before: fn(_, _) { unexpected.command("job.delete_before") },
    ),
    logs: log_store.LogStore(
      insert: fn(_) { unexpected.command("job.logs.insert") },
      list: fn(_) { unexpected.query("job.logs.list") },
      get: fn(_) { unexpected.query("job.logs.get") },
      delete_before: fn(_) { unexpected.command("job.logs.delete_before") },
    ),
    periodic: periodic_store.PeriodicStore(
      list_periodic_jobs: fn() { unexpected.query("job.periodic.list") },
      get_next_periodic_job: fn(_) { unexpected.query("job.periodic.get_next") },
      get_periodic_job_by_id: fn(_) {
        unexpected.query("job.periodic.get_by_id")
      },
      create_periodic_job: fn(_) { unexpected.command("job.periodic.create") },
      update_periodic_job: fn(_) { unexpected.command("job.periodic.update") },
    ),
    type_policies: type_policy_store.TypePolicyStore(
      list_job_type_policies: fn() { unexpected.query("job.type_policy.list") },
      get_job_type_policy_by_job_type: fn(_) {
        unexpected.query("job.type_policy.get")
      },
      upsert_job_type_policy: fn(_, _) {
        unexpected.command("job.type_policy.upsert")
      },
    ),
  )
}

pub fn new(test_state: state.State) -> ports.Ports {
  ports.Ports(
    jobs: job_store.JobStore(
      list_jobs: fn(_, _) { Ok([]) },
      summarize_jobs: fn(_, _) {
        Ok(job_model.Summary(
          total_count: 0,
          pending_count: 0,
          running_count: 0,
          failed_count: 0,
          done_count: 0,
          overdue_count: 0,
        ))
      },
      get_next_job: fn(_, _, _) { Ok(option.None) },
      get_expired_running_job: fn(_, now, status) {
        Ok(job.find_expired_job(state.get(test_state), now, status))
      },
      get_job_by_id: fn(id) { Ok(job.find_job(state.get(test_state), id)) },
      create_job: fn(value) {
        state.update(test_state, fn(db) { job.put_job(db, value) })
        Ok(Nil)
      },
      update_job: fn(value) {
        state.update(test_state, fn(db) { job.put_job(db, value) })
        Ok(Nil)
      },
      claim_queue_slot: fn(_, _, _) { Ok(True) },
      release_queue_slot: fn(_, _) { Ok(Nil) },
      delete_job: fn(id) {
        state.update(test_state, fn(db) { job.delete_job_by_id(db, id) })
        Ok(Nil)
      },
      delete_before: fn(before, statuses) {
        state.update(test_state, fn(db) {
          job.delete_jobs_before_by_statuses(db, before, statuses)
        })
        Ok(Nil)
      },
    ),
    logs: log_store.LogStore(
      insert: fn(_) { Ok(Nil) },
      list: fn(_) { Ok([]) },
      get: fn(_) { Ok(option.None) },
      delete_before: fn(_) { Ok(Nil) },
    ),
    periodic: periodic_store.PeriodicStore(
      list_periodic_jobs: fn() {
        Ok(job.list_periodic_jobs(state.get(test_state)))
      },
      get_next_periodic_job: fn(now) {
        Ok(job.find_next_periodic_job(state.get(test_state), now))
      },
      get_periodic_job_by_id: fn(id) {
        Ok(job.find_periodic_job_by_id(state.get(test_state), id))
      },
      create_periodic_job: fn(value) {
        state.update(test_state, fn(db) { job.put_periodic_job(db, value) })
        Ok(Nil)
      },
      update_periodic_job: fn(value) {
        state.update(test_state, fn(db) { job.put_periodic_job(db, value) })
        Ok(Nil)
      },
    ),
    type_policies: type_policy_store.TypePolicyStore(
      list_job_type_policies: fn() {
        Ok(job.list_job_type_policies(state.get(test_state)))
      },
      get_job_type_policy_by_job_type: fn(job_type) {
        Ok(job.find_job_type_policy(state.get(test_state), job_type))
      },
      upsert_job_type_policy: fn(value, _) {
        state.update(test_state, fn(db) {
          job.upsert_test_job_type_policy(db, value)
        })
        Ok(Nil)
      },
    ),
  )
}
