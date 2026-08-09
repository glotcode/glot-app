import gleam/json
import gleam/list
import glot_core/auth/login_dto
import glot_core/auth/login_token_dto
import glot_core/contact_dto
import glot_core/email/email_address_model.{type EmailAddress}
import glot_core/language
import glot_core/pageview_dto
import glot_core/pagination_model
import glot_core/public_action
import glot_core/run
import glot_core/snippet/snippet_dto
import glot_frontend/api/client
import glot_frontend/api/request
import glot_frontend/api/response
import glot_frontend/api/transport
import lustre/effect

pub fn send_login_token(
  email: EmailAddress,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(
      action: public_action.SendLoginTokenAction,
      data: login_token_dto.LoginTokenRequest(email),
    )

  request.send_public(req, login_token_dto.encode, client.nil_decoder(), to_msg)
}

pub fn submit_contact(
  request: contact_dto.ContactRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(
      action: public_action.SubmitContactAction,
      data: request,
    )

  request.send_public(req, contact_dto.encode, client.nil_decoder(), to_msg)
}

pub fn track_pageview(
  request: pageview_dto.PageviewRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.TrackPageviewAction, request)

  request.send_public(req, pageview_dto.encode, client.nil_decoder(), to_msg)
}

pub fn login(
  email: EmailAddress,
  token: String,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(
      action: public_action.LoginAction,
      data: login_dto.LoginRequest(email: email, token: token),
    )

  request.send_public(req, login_dto.encode, client.nil_decoder(), to_msg)
}

pub fn run_code(
  request: run.RunRequest,
  to_msg: fn(response.Response(run.RunResult)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.RunAction, request)

  request.send_public(
    req,
    run.encode_run_request,
    run.run_result_decoder(),
    to_msg,
  )
}

pub fn cancel_run() -> effect.Effect(msg) {
  effect.from(fn(_dispatch) { transport.cancel_run_requests() })
}

pub fn get_language_version(
  request: run.GetLanguageVersionRequest,
  to_msg: fn(response.Response(run.RunResult)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.GetLanguageVersionAction, request)

  request.send_public(
    req,
    run.encode_get_language_version_request,
    run.run_result_decoder(),
    to_msg,
  )
}

pub fn create_snippet(
  request: snippet_dto.CreateSnippetRequest,
  to_msg: fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.CreateSnippetAction, request)

  request.send_public(
    req,
    fn(create_request) {
      json.object([
        #("data", snippet_dto.encode_data(create_request.data)),
      ])
    },
    snippet_dto.response_decoder(),
    to_msg,
  )
}

pub fn get_snippet(
  request: snippet_dto.GetSnippetRequest,
  to_msg: fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.GetSnippetAction, request)

  request.send_public(
    req,
    fn(get_request) {
      json.object([
        #("slug", json.string(get_request.slug)),
      ])
    },
    snippet_dto.response_decoder(),
    to_msg,
  )
}

pub fn list_public_snippets(
  request: snippet_dto.ListPublicSnippetsRequest,
  to_msg: fn(response.Response(snippet_dto.ListSnippetsResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.ListPublicSnippetsAction, request)

  request.send_public(
    req,
    fn(list_request) {
      json.object(
        list.append(
          pagination_model.encode_request_fields(list_request.pagination),
          [
            #("usernames", json.array(list_request.usernames, json.string)),
            #("languages", json.array(list_request.languages, language.encode)),
          ],
        ),
      )
    },
    snippet_dto.list_response_decoder(),
    to_msg,
  )
}

pub fn list_session_snippets(
  request: snippet_dto.ListSessionSnippetsRequest,
  to_msg: fn(response.Response(snippet_dto.ListSnippetsResponse)) -> msg,
) -> effect.Effect(msg) {
  let req =
    request.PublicRequest(public_action.ListSessionSnippetsAction, request)

  request.send_public(
    req,
    fn(list_request) {
      json.object(pagination_model.encode_request_fields(
        list_request.pagination,
      ))
    },
    snippet_dto.list_response_decoder(),
    to_msg,
  )
}

pub fn update_snippet(
  request: snippet_dto.UpdateSnippetRequest,
  to_msg: fn(response.Response(snippet_dto.SnippetResponse)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.UpdateSnippetAction, request)

  request.send_public(
    req,
    fn(update_request) {
      json.object([
        #("slug", json.string(update_request.slug)),
        #("data", snippet_dto.encode_data(update_request.data)),
      ])
    },
    snippet_dto.response_decoder(),
    to_msg,
  )
}

pub fn delete_snippet(
  request: snippet_dto.DeleteSnippetRequest,
  to_msg: fn(response.Response(Nil)) -> msg,
) -> effect.Effect(msg) {
  let req = request.PublicRequest(public_action.DeleteSnippetAction, request)

  request.send_public(
    req,
    fn(delete_request) {
      json.object([
        #("slug", json.string(delete_request.slug)),
      ])
    },
    client.nil_decoder(),
    to_msg,
  )
}
