import gleam/http/request
import gleam/list
import gleam/option
import glot_backend/app_config/effect/effect as app_config_effect
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/logging/ingestion/ports/sink.{type Sink}
import glot_backend/logging/page_log/model/entry as page_log_entry
import glot_backend/page/editor_page_domain
import glot_backend/page/snippets_page_domain
import glot_backend/page_error_presenter
import glot_backend/page_response
import glot_backend/page_theme.{type PageTheme}
import glot_backend/request_policy/availability as availability_policy
import glot_backend/static_assets
import glot_backend/system/effect/basic/basic_handlers
import glot_backend/system/effect/effect_trace
import glot_backend/system/effect/interpreter
import glot_backend/system/effect/program
import glot_backend/system/effect/program_state
import glot_backend/system/effect/program_types
import glot_backend/system/effect/runtime.{type Runtime}
import glot_backend/system/effect/total_program
import glot_backend/system/http/server_timing
import glot_backend/system/request/context
import glot_backend/system/request/hydrated_context as request_context
import glot_backend/system/runtime/erlang
import glot_core/route
import glot_web/page/seo
import glot_web/page/server
import wisp

pub type PageRequest {
  PageRequest(route: route.Route, path: String, theme: option.Option(PageTheme))
}

pub fn handle_request(
  effect_runtime: Runtime,
  ctx: context.Context,
  log_sink: Sink,
  req: wisp.Request,
) -> wisp.Response {
  let page_request = page_request_from_request(req)
  let page_response = handle_page_request(effect_runtime, ctx, page_request)
  let total_duration_ns = erlang.perf_counter_ns() - ctx.started_at
  insert_log_entry(
    ctx,
    log_sink,
    page_request,
    page_response,
    total_duration_ns,
  )

  page_response.response
  |> wisp.set_header(
    "Server-Timing",
    server_timing.prepare(page_response.effects, total_duration_ns),
  )
}

fn page_request_from_request(req: wisp.Request) -> PageRequest {
  let uri = request.to_uri(req)
  let path = case uri.query {
    option.Some(query) -> uri.path <> "?" <> query
    option.None -> uri.path
  }

  let theme_cookie =
    req
    |> request.get_cookies
    |> list.key_find(page_theme.cookie_name)
  let theme = case theme_cookie {
    Ok(value) -> page_theme.parse(value) |> option.from_result()
    Error(_) -> option.None
  }

  PageRequest(route: route.from_uri(uri), path: path, theme: theme)
}

fn handle_page_request(
  effect_runtime: Runtime,
  ctx: context.Context,
  page_request: PageRequest,
) -> page_response.PageResponse {
  case static_assets.load(ctx.config.static_base_path) {
    Ok(assets) -> {
      let #(page_result, availability_state) =
        page_config_and_availability(ctx, page_request.route)
        |> interpreter.run(effect_runtime, ctx)

      case page_result {
        Ok(#(request_ctx, availability_policy.AllowPage)) ->
          handle_page_request_with_runtime(
            effect_runtime,
            request_ctx,
            page_request,
            assets,
          )
          |> prepend_effects(availability_state.effect_measurements)
        Ok(#(
          _,
          availability_policy.UnavailablePage(message, retry_after_seconds),
        )) ->
          page_error_presenter.unavailable_page_response(
            availability_state,
            assets.stylesheet_href,
            page_request.theme,
            message,
            retry_after_seconds,
          )
        Error(err) ->
          page_error_presenter.internal_page_error(
            "availability page",
            err,
            availability_state,
          )
      }
    }
    Error(message) -> static_assets_error_response(message)
  }
}

fn page_config_and_availability(
  ctx: context.Context,
  page_route: route.Route,
) -> program_types.Program(
  #(
    request_context.RequestContext,
    availability_policy.PageAvailabilityDecision,
  ),
) {
  use config <- program.and_then(app_config_effect.get_dynamic_config())
  let request_ctx = request_context.new(ctx, config)
  availability_policy.evaluate_page_route(
    dynamic_config.availability_config(config),
    page_route,
  )
  |> program.map(fn(decision) { #(request_ctx, decision) })
}

fn handle_page_request_with_runtime(
  runtime: Runtime,
  request_ctx: request_context.RequestContext,
  page_request: PageRequest,
  assets: static_assets.Assets,
) -> page_response.PageResponse {
  let ctx = request_ctx.context
  let social_image_url = seo.site_url <> assets.social_image_href
  let public_spa = fn(metadata) {
    spa_page(assets, metadata, page_request.theme)
  }
  let private_spa = fn(title) {
    spa_page(
      assets,
      seo.metadata(
        title: title,
        description: "Secure glot.io account page.",
        canonical_path: route.to_string(page_request.route),
        index: False,
        open_graph_type: "website",
      ),
      page_request.theme,
    )
  }
  let admin_spa = fn(title) {
    admin_spa_page(
      assets,
      seo.metadata(
        title: title,
        description: "Private glot.io administration page.",
        canonical_path: route.to_string(page_request.route),
        index: False,
        open_graph_type: "website",
      ),
      page_request.theme,
    )
  }

  case page_request.route {
    route.Public(route.Home) -> {
      let state = empty_page_state()
      page_response.PageResponse(
        response: wisp.html_response(
          server.home_document(
            public_render_config(assets, page_request.theme),
            social_image_url,
          ),
          200,
        ),
        status_code: 200,
        render_mode: "ssr",
        effects: [],
        info: state.info_fields,
        warnings: state.warning_fields,
        debug: state.debug_fields,
        error: option.None,
      )
    }
    route.Public(route.Contact) -> {
      let state = empty_page_state()
      page_response.PageResponse(
        response: wisp.html_response(
          server.contact_document(public_render_config(
            assets,
            page_request.theme,
          )),
          200,
        ),
        status_code: 200,
        render_mode: "ssr",
        effects: [],
        info: state.info_fields,
        warnings: state.warning_fields,
        debug: state.debug_fields,
        error: option.None,
      )
    }
    route.Public(route.Privacy) -> {
      let state = empty_page_state()
      page_response.PageResponse(
        response: wisp.html_response(
          server.privacy_document(public_render_config(
            assets,
            page_request.theme,
          )),
          200,
        ),
        status_code: 200,
        render_mode: "ssr",
        effects: [],
        info: state.info_fields,
        warnings: state.warning_fields,
        debug: state.debug_fields,
        error: option.None,
      )
    }
    route.Public(route.Login) -> public_spa(seo.login())
    route.Account(route.AccountHome) -> private_spa("Account | glot.io")
    route.Account(route.AccountSnippets(_, _, _)) ->
      private_spa("Your snippets | glot.io")
    route.Admin(route.AdminHome) -> admin_spa("glot.io - admin")
    route.Admin(route.AdminApiLogs(_)) -> admin_spa("glot.io - api logs")
    route.Admin(route.AdminApiLog(_)) -> admin_spa("glot.io - api log")
    route.Admin(route.AdminRunLogs(_)) -> admin_spa("glot.io - run logs")
    route.Admin(route.AdminRunLog(_)) -> admin_spa("glot.io - run log")
    route.Admin(route.AdminPeriodicJobs) -> admin_spa("glot.io - periodic jobs")
    route.Admin(route.AdminPeriodicJob(_)) ->
      admin_spa("glot.io - periodic job")
    route.Admin(route.AdminUsers(_)) -> admin_spa("glot.io - admin users")
    route.Admin(route.AdminUser(_)) -> admin_spa("glot.io - admin user")
    route.Admin(route.AdminJobs(_)) -> admin_spa("glot.io - admin jobs")
    route.Admin(route.AdminJob(_)) -> admin_spa("glot.io - admin job")
    route.Admin(route.AdminEmailTemplates) ->
      admin_spa("glot.io - email templates")
    route.Admin(route.AdminEmailTemplate(_)) ->
      admin_spa("glot.io - email template")
    route.Admin(route.AdminSnippets(_)) -> admin_spa("glot.io - admin snippets")
    route.Admin(route.AdminSnippet(_)) -> admin_spa("glot.io - admin snippet")
    route.Admin(route.AdminJobLogs(_)) -> admin_spa("glot.io - job logs")
    route.Admin(route.AdminJobLog(_)) -> admin_spa("glot.io - job log")
    route.Admin(route.AdminConfig) -> admin_spa("glot.io - admin config")
    route.Admin(route.AdminRateLimits) ->
      admin_spa("glot.io - admin rate limits")
    route.Admin(route.AdminJobTypePolicies) ->
      admin_spa("glot.io - admin job type policies")
    route.Public(route.Snippets(after:, before:, username:, language:)) ->
      run_page_program(
        "snippets page",
        snippets_page_domain.load_view_model(
          request_ctx,
          after,
          before,
          username,
          language,
        ),
        runtime,
        ctx,
        fn(view_model) {
          server.snippets_document(
            public_render_config(assets, page_request.theme),
            view_model,
            route.to_string(page_request.route),
            social_image_url,
          )
        },
      )
    route.Public(route.NewSnippet(language_slug)) ->
      run_page_program(
        "new snippet page",
        editor_page_domain.load_new_view_model(language_slug),
        runtime,
        ctx,
        fn(view_model) {
          server.editor_document(
            render_config(
              assets,
              page_request.theme,
              assets.frontend_src,
              list.append(assets.frontend_preloads, assets.code_mirror_preloads),
              [],
            ),
            view_model,
            social_image_url,
          )
        },
      )
    route.Public(route.Snippet(slug)) ->
      run_page_program(
        "snippet page",
        editor_page_domain.load_existing_view_model(request_ctx, slug),
        runtime,
        ctx,
        fn(view_model) {
          server.editor_document(
            render_config(
              assets,
              page_request.theme,
              assets.frontend_src,
              list.append(assets.frontend_preloads, assets.code_mirror_preloads),
              [],
            ),
            view_model,
            social_image_url,
          )
        },
      )
    route.NotFound(_) -> {
      let state = empty_page_state()
      page_response.PageResponse(
        response: wisp.not_found(),
        status_code: 404,
        render_mode: "not_found",
        effects: [],
        info: state.info_fields,
        warnings: state.warning_fields,
        debug: state.debug_fields,
        error: option.None,
      )
    }
  }
}

fn static_assets_error_response(message: String) -> page_response.PageResponse {
  let state = empty_page_state()
  page_response.PageResponse(
    response: wisp.html_response(
      "Static asset manifest error: " <> message,
      500,
    ),
    status_code: 500,
    render_mode: "static_assets_error",
    effects: [],
    info: state.info_fields,
    warnings: state.warning_fields,
    debug: state.debug_fields,
    error: option.None,
  )
}

fn spa_page(
  assets: static_assets.Assets,
  metadata: seo.Metadata,
  theme: option.Option(PageTheme),
) -> page_response.PageResponse {
  spa_page_with_frontend(
    assets,
    metadata,
    assets.frontend_src,
    assets.frontend_preloads,
    [],
    theme,
  )
}

fn admin_spa_page(
  assets: static_assets.Assets,
  metadata: seo.Metadata,
  theme: option.Option(PageTheme),
) -> page_response.PageResponse {
  spa_page_with_frontend(
    assets,
    metadata,
    assets.admin_frontend_src,
    assets.admin_frontend_preloads,
    assets.admin_stylesheet_hrefs,
    theme,
  )
}

fn spa_page_with_frontend(
  assets: static_assets.Assets,
  metadata: seo.Metadata,
  frontend_src: String,
  frontend_preloads: List(String),
  additional_stylesheet_hrefs: List(String),
  theme: option.Option(PageTheme),
) -> page_response.PageResponse {
  let state = empty_page_state()
  page_response.PageResponse(
    response: wisp.html_response(
      server.spa_document(
        render_config(
          assets,
          theme,
          frontend_src,
          frontend_preloads,
          additional_stylesheet_hrefs,
        ),
        metadata,
        seo.site_url <> assets.social_image_href,
      ),
      200,
    ),
    status_code: 200,
    render_mode: "spa",
    effects: [],
    info: state.info_fields,
    warnings: state.warning_fields,
    debug: state.debug_fields,
    error: option.None,
  )
}

fn run_page_program(
  page_name: String,
  total_program: total_program.TotalProgram(a),
  runtime: Runtime,
  ctx: context.Context,
  render_document: fn(a) -> String,
) -> page_response.PageResponse {
  let #(result, state) =
    total_program
    |> total_program.to_program
    |> interpreter.run(runtime, ctx)

  case result {
    Ok(value) ->
      page_response.PageResponse(
        response: wisp.html_response(render_document(value), 200),
        status_code: 200,
        render_mode: "ssr",
        effects: state.effect_measurements,
        info: state.info_fields,
        warnings: state.warning_fields,
        debug: state.debug_fields,
        error: option.None,
      )
    Error(err) ->
      page_error_presenter.internal_page_error(page_name, err, state)
  }
}

fn public_render_config(
  assets: static_assets.Assets,
  theme: option.Option(PageTheme),
) -> server.RenderConfig {
  render_config(
    assets,
    theme,
    assets.frontend_src,
    assets.frontend_preloads,
    [],
  )
}

fn render_config(
  assets: static_assets.Assets,
  theme: option.Option(PageTheme),
  frontend_src: String,
  frontend_preloads: List(String),
  additional_stylesheet_hrefs: List(String),
) -> server.RenderConfig {
  server.RenderConfig(
    theme: option.map(theme, page_theme.to_string),
    stylesheet_href: assets.stylesheet_href,
    additional_stylesheet_hrefs: additional_stylesheet_hrefs,
    frontend_src: frontend_src,
    frontend_preloads: frontend_preloads,
  )
}

fn empty_page_state() -> program_state.State {
  program_state.new_state()
}

fn insert_log_entry(
  ctx: context.Context,
  log_sink: Sink,
  page_request: PageRequest,
  page_response: page_response.PageResponse,
  total_duration_ns: Int,
) -> Nil {
  log_sink.write_page(prepare_log_entry(
    ctx,
    page_request,
    page_response,
    total_duration_ns,
  ))
}

fn prepare_log_entry(
  ctx: context.Context,
  page_request: PageRequest,
  page_response: page_response.PageResponse,
  total_duration_ns: Int,
) -> page_log_entry.Entry {
  page_log_entry.Entry(
    id: basic_handlers.uuid_v7(ctx.timestamp),
    request_id: ctx.request_id,
    created_at: ctx.timestamp,
    route: route.name(page_request.route),
    path: page_request.path,
    status_code: page_response.status_code,
    render_mode: page_response.render_mode,
    duration_ns: total_duration_ns,
    ip: ctx.client_info.ip,
    user_agent: ctx.client_info.user_agent,
    referrer: ctx.client_info.referrer,
    info: page_response.info,
    warnings: page_response.warnings,
    debug: page_response.debug,
    error: page_response.error,
    effects: page_response.effects,
  )
}

fn prepend_effects(
  page_response: page_response.PageResponse,
  effects: List(effect_trace.EffectMeasurement),
) -> page_response.PageResponse {
  page_response.PageResponse(
    ..page_response,
    effects: list.append(effects, page_response.effects),
  )
}
