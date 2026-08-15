import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import glot_backend/job/ports/executor_control.{type ExecutorControl}
import glot_backend/job/ports/tracker.{type Tracker}
import glot_backend/logging/ingestion/ports/sink.{type Sink}
import glot_backend/system/lifecycle/request_tracker/ports/request_tracker.{
  type RequestTracker,
}
import glot_backend/system/lifecycle/server_mode/ports/controller.{
  type Controller,
}
import glot_backend/system/runtime/erlang
import wisp

const drain_poll_interval_ms = 100

const drain_timeout_ms = 30_000

const interruption_timeout_ms = 10_000

pub type SignalMessage {
  SigtermReceived
}

pub fn wait_for_signal(
  signal_subject: process.Subject(SignalMessage),
  log_sink: Sink,
  server_mode: Controller,
  request_tracker: RequestTracker,
  job_tracker: Tracker,
  job_executors: List(ExecutorControl),
) -> Nil {
  case process.receive_forever(signal_subject) {
    SigtermReceived -> {
      wisp.log_warning("SIGTERM received")
      server_mode.enter_shutting_down()
      wisp.log_warning("Server mode changed to ShuttingDown")
      drain_work(
        request_tracker,
        job_tracker,
        job_executors,
        log_sink,
        drain_timeout_ms,
      )
    }
  }
}

fn drain_work(
  request_tracker: RequestTracker,
  job_tracker: Tracker,
  job_executors: List(ExecutorControl),
  log_sink: Sink,
  remaining_ms: Int,
) -> Nil {
  let in_flight_request_count = request_tracker.count()
  let in_flight_job_count = job_tracker.count()
  let total_in_flight_count = in_flight_request_count + in_flight_job_count

  case total_in_flight_count == 0 {
    True -> {
      finish_shutdown(log_sink, "No in-flight requests or jobs remain")
    }
    False -> {
      case remaining_ms <= 0 {
        True -> {
          io.println(
            "Graceful drain timed out with "
            <> int.to_string(in_flight_request_count)
            <> " in-flight requests and "
            <> int.to_string(in_flight_job_count)
            <> " in-flight jobs remaining; interrupting active jobs",
          )
          interrupt_and_drain(
            request_tracker,
            job_tracker,
            job_executors,
            log_sink,
            erlang.perf_counter_ns() + { interruption_timeout_ms * 1_000_000 },
          )
        }
        False -> {
          process.sleep(drain_poll_interval_ms)
          drain_work(
            request_tracker,
            job_tracker,
            job_executors,
            log_sink,
            remaining_ms - drain_poll_interval_ms,
          )
        }
      }
    }
  }
}

fn interrupt_and_drain(
  request_tracker: RequestTracker,
  job_tracker: Tracker,
  job_executors: List(ExecutorControl),
  log_sink: Sink,
  deadline_ns: Int,
) -> Nil {
  list.each(job_executors, fn(executor) {
    let executor_control.ExecutorControl(interrupt_for_shutdown:) = executor
    case interrupt_for_shutdown() {
      Ok(Nil) -> Nil
      Error(message) ->
        io.println("Failed to interrupt a job executor: " <> message)
    }
  })

  let in_flight_request_count = request_tracker.count()
  let in_flight_job_count = job_tracker.count()
  case in_flight_request_count + in_flight_job_count == 0 {
    True -> finish_shutdown(log_sink, "Interrupted jobs were safely requeued")
    False ->
      case erlang.perf_counter_ns() >= deadline_ns {
        True ->
          finish_shutdown(
            log_sink,
            "Shutdown interruption timed out with "
              <> int.to_string(in_flight_request_count)
              <> " in-flight requests and "
              <> int.to_string(in_flight_job_count)
              <> " in-flight jobs remaining",
          )
        False -> {
          process.sleep(drain_poll_interval_ms)
          interrupt_and_drain(
            request_tracker,
            job_tracker,
            job_executors,
            log_sink,
            deadline_ns,
          )
        }
      }
  }
}

fn finish_shutdown(log_sink: Sink, message: String) -> Nil {
  log_sink.drain()
  io.println(message <> ", shutting down")
  erlang.halt()
}
