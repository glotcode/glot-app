import glot_backend/job/adapter/postgres/job/read
import glot_backend/job/adapter/postgres/job/write
import glot_backend/job/ports/job_store
import glot_backend/system/database as db_helpers

pub fn new(db: db_helpers.Db) -> job_store.JobStore {
  job_store.JobStore(
    list_jobs: fn(filter, pagination) { read.list(db, filter, pagination) },
    summarize_jobs: fn(filter, now) { read.summarize(db, filter, now) },
    get_next_job: fn(queue, now, pending_status) {
      read.get_next(db, queue, now, pending_status)
    },
    get_expired_running_job: fn(queue, now, running_status) {
      read.get_expired_running(db, queue, now, running_status)
    },
    get_job_by_id: fn(id) { read.get_by_id(db, id) },
    create_job: fn(job) { write.create(db, job) },
    update_job: fn(job) { write.update(db, job) },
    claim_queue_slot: fn(queue, job_id, lease_expires_at) {
      write.claim_queue_slot(db, queue, job_id, lease_expires_at)
    },
    release_queue_slot: fn(job_id, lease_expires_at) {
      write.release_queue_slot(db, job_id, lease_expires_at)
    },
    delete_job: fn(id) { write.delete(db, id) },
    delete_before: fn(before, statuses) {
      write.delete_before(db, before, statuses)
    },
  )
}
