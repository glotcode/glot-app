import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import glot_backend/auth/domain/session/current as current_session
import glot_backend/system/effect/basic/basic_effect
import glot_backend/system/effect/log
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_backend/system/request/hydrated_context.{type RequestContext}
import glot_core/pageview_dto.{type PageviewRequest}
import youid/uuid.{type Uuid}

pub type TrackedPageview {
  TrackedPageview(
    id: Uuid,
    session_id: Option(Uuid),
    user_id: Option(Uuid),
    route: String,
    path: String,
  )
}

pub fn track_pageview(
  request_ctx: RequestContext,
  request: PageviewRequest,
) -> Program(TrackedPageview) {
  use maybe_session <- program.and_then(current_session.get_session(request_ctx))
  let maybe_session_id =
    option.map(maybe_session, fn(session) { session.identity.id })
  let maybe_user_id =
    option.map(maybe_session, fn(session) { session.user.identity.id })

  use _ <- program.and_then(
    basic_effect.info(
      log.from_list([
        log.uuid("pageview_id", request.id),
        log.string("route", request.route),
        log.string("path", request.path),
        log.optional_uuid("session_id", maybe_session_id),
        log.optional_uuid("user_id", maybe_user_id),
      ]),
    ),
  )

  program.succeed(TrackedPageview(
    id: request.id,
    session_id: maybe_session_id,
    user_id: maybe_user_id,
    route: request.route,
    path: request.path,
  ))
}

pub fn request_from_dynamic(data: Dynamic) -> Program(PageviewRequest) {
  program.decode_dynamic(data, pageview_dto.decoder())
}
