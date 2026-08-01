import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/result
import glot_backend/auth/domain/session/current as current_session
import glot_backend/job/effect/job/effect as job_effect
import glot_backend/request_policy/api_action as api_action_policy
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_backend/user_action/effect/effect as user_action_effect
import glot_core/admin/job_dto.{
  type ListJobsRequest, type ListJobsResponse, type StatusFilter,
}
import glot_core/admin_action
import glot_core/api_action
import glot_core/job/job_model.{type ListJobsFilter, type Status}
import glot_core/pagination_model
import youid/uuid

pub fn get_jobs(
  request_ctx: RequestContext,
  request: ListJobsRequest,
) -> Program(ListJobsResponse) {
  let ctx = request_ctx.context

  let pagination = request.pagination
  use _ <- program.and_then(
    pagination_model.validate(pagination, 100)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  use session <- program.and_then(current_session.require_session(request_ctx))
  use user_action <- program.and_then(api_action_policy.enforce(
    request_ctx: request_ctx,
    action: api_action.admin(admin_action.GetAdminJobsAction),
    actor: api_action_policy.actor_from_user(option.Some(session.user)),
  ))

  let filter = request_to_filter(request)

  use jobs <- program.and_then(job_effect.list_jobs(
    filter: filter,
    pagination: pagination_model.increment_limit(pagination),
  ))
  use summary <- program.and_then(job_effect.summarize_jobs(
    filter,
    ctx.timestamp,
  ))

  let page =
    pagination_model.paginate(jobs, pagination, fn(job) {
      pagination_model.from_string(uuid.to_string(job.id))
    })

  use _ <- program.and_then(user_action_effect.create_user_action(user_action))

  program.succeed(job_dto.from_jobs(
    summary: summary,
    page: page,
    now: ctx.timestamp,
  ))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(ListJobsRequest) {
  program.decode_dynamic(data, job_dto.list_request_decoder())
}

fn request_to_filter(request: ListJobsRequest) -> ListJobsFilter {
  job_model.new_list_filter()
  |> job_model.with_statuses(statuses_for_filter(request.status_filter))
  |> job_model.with_job_type(request.job_type_filter)
  |> job_model.with_periodic_job_id(request.periodic_job_id)
}

fn statuses_for_filter(filter: StatusFilter) -> List(Status) {
  case filter {
    job_dto.AllStatuses -> []
    job_dto.PendingStatus -> [job_model.Pending]
    job_dto.RunningStatus -> [job_model.Running]
    job_dto.FailedStatus -> [job_model.Failed]
    job_dto.DoneStatus -> [job_model.Done]
  }
}
