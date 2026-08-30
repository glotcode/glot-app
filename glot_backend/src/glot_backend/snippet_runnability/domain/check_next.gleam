import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/job/domain/finalization.{type Finalization}
import glot_backend/run_code/effect/effect as run_code_effect
import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_core/language
import glot_core/run
import glot_core/snippet/runnability
import glot_core/snippet/snippet_model.{type Snippet}

pub type Outcome {
  NoCandidate
  Processed(finalize: TransactionProgram(Finalization))
}

type Attempt {
  Checked(is_runnable: Bool)
  SnippetRejected(error_code: String)
}

const retry_limit_exceeded = "retry_limit_exceeded"

pub fn check_next(_ctx: Context, max_attempts: Int) -> Program(Outcome) {
  use candidate <- program.and_then(
    snippet_effect.get_newest_unchecked_runnability(),
  )
  case candidate {
    option.None -> program.succeed(NoCandidate)
    option.Some(candidate) -> check_candidate(candidate, max_attempts)
  }
}

fn check_candidate(
  candidate: runnability.Candidate,
  max_attempts: Int,
) -> Program(Outcome) {
  let runnability.Candidate(snippet, expected_updated_at, attempts) = candidate
  case language.is_runnable(snippet.language) {
    False -> store_result(snippet, expected_updated_at, False)
    True ->
      check_runnable_candidate(
        snippet,
        expected_updated_at,
        attempts,
        max_attempts,
      )
  }
}

fn check_runnable_candidate(
  snippet: Snippet,
  expected_updated_at: Timestamp,
  attempts: Int,
  max_attempts: Int,
) -> Program(Outcome) {
  case attempts >= max_attempts {
    True -> store_failure(snippet, expected_updated_at, retry_limit_exceeded)
    False -> {
      use recorded <- program.and_then(
        snippet_effect.increment_runnability_check_attempts(
          snippet.id,
          expected_updated_at,
        ),
      )
      case recorded {
        runnability.Stale -> stale_candidate(snippet)
        runnability.Stored ->
          run_candidate(
            snippet,
            expected_updated_at,
            attempts + 1 >= max_attempts,
          )
      }
    }
  }
}

fn run_candidate(
  snippet: Snippet,
  expected_updated_at: Timestamp,
  retry_limit_reached: Bool,
) -> Program(Outcome) {
  let request =
    run.snippet_request(
      snippet.language,
      snippet.run_instructions,
      snippet.files,
      case snippet.stdin == "" {
        True -> option.None
        False -> option.Some(snippet.stdin)
      },
    )
  use attempt <- program.and_then(
    run_code_effect.run_code_from_dynamic_config(request)
    |> program.map(run_result_to_attempt)
    |> program.attempt(fn(err) {
      case err, retry_limit_reached {
        error.InfraError(infra_error.RunRequestClientError(message)), _ ->
          program.succeed(SnippetRejected("invalid_run_request:" <> message))
        _, True ->
          program.succeed(SnippetRejected(
            retry_limit_exceeded <> ":" <> error.to_string(err),
          ))
        _, False -> program.fail(err)
      }
    }),
  )
  case attempt {
    Checked(is_runnable) ->
      store_result(snippet, expected_updated_at, is_runnable)
    SnippetRejected(error_code) ->
      store_failure(snippet, expected_updated_at, error_code)
  }
}

fn run_result_to_attempt(result: run.RunResult) -> Attempt {
  case result {
    Ok(success) -> Checked(success.error == "")
    Error(_) -> Checked(False)
  }
}

fn store_result(
  snippet: Snippet,
  expected_updated_at: Timestamp,
  is_runnable: Bool,
) -> Program(Outcome) {
  use checked_at <- program.and_then(basic_effect.system_time())
  program.succeed(Processed(
    snippet_effect.store_runnability_tx(
      snippet.id,
      expected_updated_at,
      runnability.CheckResult(is_runnable:, checked_at:),
    )
    |> transaction_program.map(fn(result) {
      finalization(result, snippet, "snippet_runnability_stale")
    }),
  ))
}

fn store_failure(
  snippet: Snippet,
  expected_updated_at: Timestamp,
  error_code: String,
) -> Program(Outcome) {
  use _ <- program.and_then(
    basic_effect.warn(
      log.from_list([
        log.uuid("snippet_id", snippet.id),
        log.string("runnability_check_error", error_code),
      ]),
    ),
  )
  use failed_at <- program.and_then(basic_effect.system_time())
  program.succeed(Processed(
    snippet_effect.store_runnability_check_failure_tx(
      snippet.id,
      expected_updated_at,
      runnability.CheckFailure(error_code:, failed_at:),
    )
    |> transaction_program.map(fn(result) {
      finalization(result, snippet, "snippet_runnability_failure_stale")
    }),
  ))
}

fn stale_candidate(snippet: Snippet) -> Program(Outcome) {
  program.succeed(
    Processed(
      transaction_program.succeed(
        finalization.Skipped(stale_fields(snippet, "snippet_runnability_stale")),
      ),
    ),
  )
}

fn finalization(
  result: runnability.StoreResult,
  snippet: Snippet,
  stale_field: String,
) -> Finalization {
  case result {
    runnability.Stored -> finalization.Applied
    runnability.Stale ->
      finalization.Skipped(stale_fields(snippet, stale_field))
  }
}

fn stale_fields(snippet: Snippet, field: String) -> log.Fields {
  log.from_list([
    log.uuid("snippet_id", snippet.id),
    log.bool(field, True),
  ])
}
