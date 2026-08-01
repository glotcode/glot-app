import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/auth/domain/session/current as current_session
import glot_backend/logging/run_log/effect/effect as run_log_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/run_code/domain/observation.{type Observation}
import glot_backend/run_code/domain/validation as run_validation
import glot_backend/run_code/effect/effect as run_code_effect
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_effect
import glot_backend/system/effect/transaction/transaction_program
import glot_backend/system/request/context.{type Context}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/api_action
import glot_core/language.{type Language}
import glot_core/public_action
import glot_core/run.{type RunRequest, type RunResult}
import glot_core/run_log_model.{type RunLog}
import glot_core/user_action.{type UserAction}
import youid/uuid.{type Uuid}

pub fn run(
  request_ctx: RequestContext,
  request: RunRequest,
) -> Program(RunResult) {
  let ctx = request_ctx.context
  let config = request_ctx.dynamic_config

  use request_language <- program.and_then(run_validation.require_valid_request(
    request,
  ))

  use maybe_session <- program.and_then(current_session.get_session(request_ctx))
  let maybe_session_id =
    option.map(maybe_session, fn(session) { session.identity.id })
  let maybe_user_id =
    option.map(maybe_session, fn(session) { session.user.identity.id })
  let maybe_user = option.map(maybe_session, fn(session) { session.user })

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.string("image", request.image),
        log.string("language", language.to_string(request_language)),
        log.optional_uuid("session_id", maybe_session_id),
        log.optional_uuid("user_id", maybe_user_id),
      ]),
    ),
  )

  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.public(public_action.RunAction),
    actor: api_action_policy.actor_from_user(maybe_user),
  ))

  use run_result <- program.and_then(run_code_effect.run_code(
    dynamic_config.docker_run_config(config),
    request,
  ))
  let observation = observation.from_run_result(run_result)

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.string(
          "run_outcome",
          run_log_model.run_outcome_to_string(observation.outcome),
        ),
        log.optional_int("run_duration_ns", observation.duration_ns),
        log.optional_string("run_failure_message", observation.failure_message),
      ]),
    ),
  )

  use run_log_id <- program.and_then(basic_effect.uuid_v7())
  let run_log =
    prepare_run_log(
      id: run_log_id,
      ctx: ctx,
      session_id: maybe_session_id,
      user_id: maybe_user_id,
      language: request_language,
      observation: observation,
    )

  use _ <- program.and_then(
    persist_run_tx(user_action, run_log)
    |> transaction_effect.run(),
  )

  program.succeed(run_result)
}

pub fn request_from_dynamic(data: Dynamic) -> Program(RunRequest) {
  program.decode_dynamic(data, run.run_request_decoder())
}

fn prepare_run_log(
  id id: Uuid,
  ctx ctx: Context,
  session_id session_id: Option(Uuid),
  user_id user_id: Option(Uuid),
  language language: Language,
  observation observation: Observation,
) -> RunLog {
  run_log_model.RunLog(
    id: id,
    request_id: ctx.request_id,
    created_at: ctx.timestamp,
    session_id: session_id,
    user_id: user_id,
    language: language,
    outcome: observation.outcome,
    duration_ns: observation.duration_ns,
    failure_message: observation.failure_message,
  )
}

fn persist_run_tx(
  user_action: UserAction,
  run_log: RunLog,
) -> TransactionProgram(Nil) {
  transaction_program.sequence([
    user_action_effect.create_user_action_tx(user_action),
    run_log_effect.create_tx(run_log),
  ])
}
