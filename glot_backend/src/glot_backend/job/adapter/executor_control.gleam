import gleam/erlang/process
import glot_backend/job/ports/executor_control.{type ExecutorControl}
import glot_backend/job/worker/executor/worker

pub fn new(subject: process.Subject(worker.Message)) -> ExecutorControl {
  executor_control.ExecutorControl(interrupt_for_shutdown: fn() {
    worker.interrupt_for_shutdown(subject)
  })
}
