import gleam/int
import gleam/json
import gleam/list
import gleam/option
import glot_core/route
import glot_web/page/contact
import glot_web/page/editor
import glot_web/page/home
import glot_web/page/privacy
import glot_web/page/seo
import glot_web/page/site_chrome
import glot_web/page/snippets
import glot_web/page/ssr_data as ssr_data_view
import glot_web/page/top_bar
import glot_web/route as web_route
import lustre/attribute
import lustre/element
import lustre/element/html

pub type RenderConfig {
  RenderConfig(
    theme: option.Option(String),
    stylesheet_href: String,
    additional_stylesheet_hrefs: List(String),
    frontend_src: String,
    frontend_preloads: List(String),
  )
}

pub fn home_document(config: RenderConfig, social_image_url: String) -> String {
  document(
    config: config,
    title: seo.home() |> seo.title,
    head_children: seo.append(
      seo.head_children(seo.home(), option.Some(social_image_url)),
      [seo.home_structured_data()],
    ),
    include_frontend: True,
    ssr_data: option.None,
    app_attributes: [],
    app_children: [
      site_chrome.view(
        top_bar_model: top_bar.empty_model(),
        footer_account_route: route.Account(route.AccountHome),
        content: home.view(load_ad: False),
      ),
    ],
  )
}

pub fn contact_document(config: RenderConfig) -> String {
  document(
    config: config,
    title: seo.contact() |> seo.title,
    head_children: seo.head_children(seo.contact(), option.None),
    include_frontend: True,
    ssr_data: option.None,
    app_attributes: [],
    app_children: [
      site_chrome.view(
        top_bar_model: top_bar.empty_model(),
        footer_account_route: route.Account(route.AccountHome),
        content: contact.view(contact.contact_form_placeholder()),
      ),
    ],
  )
}

pub fn privacy_document(config: RenderConfig) -> String {
  document(
    config: config,
    title: seo.privacy() |> seo.title,
    head_children: seo.head_children(seo.privacy(), option.None),
    include_frontend: True,
    ssr_data: option.None,
    app_attributes: [],
    app_children: [
      site_chrome.view(
        top_bar_model: top_bar.empty_model(),
        footer_account_route: route.Account(route.AccountHome),
        content: privacy.view(),
      ),
    ],
  )
}

pub fn spa_document(
  config: RenderConfig,
  metadata: seo.Metadata,
  social_image_url: String,
) -> String {
  document(
    config: config,
    title: seo.title(metadata),
    head_children: seo.head_children(metadata, option.Some(social_image_url)),
    include_frontend: True,
    ssr_data: option.None,
    app_attributes: [],
    app_children: [],
  )
}

pub fn snippets_document(
  config: RenderConfig,
  view_model: snippets.ViewModel,
  canonical_path: String,
  social_image_url: String,
) -> String {
  let metadata = seo.snippets(view_model.username, canonical_path)
  document(
    config: config,
    title: seo.title(metadata),
    head_children: seo.head_children(metadata, option.Some(social_image_url)),
    include_frontend: True,
    ssr_data: option.Some(snippets.encode(view_model)),
    app_attributes: [],
    app_children: [
      site_chrome.view(
        top_bar_model: top_bar.empty_model(),
        footer_account_route: route.Account(route.AccountHome),
        content: snippets.view(view_model, True),
      ),
    ],
  )
}

pub fn editor_document(
  config: RenderConfig,
  view_model: editor.ViewModel,
  social_image_url: String,
) -> String {
  document(
    config: config,
    title: editor.title(view_model),
    head_children: editor.head_children(
      view_model,
      option.Some(social_image_url),
    ),
    include_frontend: True,
    ssr_data: option.Some(editor.encode(view_model)),
    app_attributes: [],
    app_children: [editor.render(view_model)],
  )
}

pub fn unavailable_document(
  config: RenderConfig,
  message: String,
  retry_after_seconds: option.Option(Int),
) -> String {
  document(
    config: config,
    title: "glot.io - unavailable",
    head_children: [],
    include_frontend: False,
    ssr_data: option.None,
    app_attributes: [attribute.class("maintenance-page")],
    app_children: [
      html.main([attribute.class("maintenance-page__shell")], [
        html.section([attribute.class("maintenance-page__panel")], [
          html.p([attribute.class("maintenance-page__eyebrow")], [
            html.text("Availability mode"),
          ]),
          html.h1([attribute.class("maintenance-page__title")], [
            html.text("Temporarily unavailable"),
          ]),
          html.p([attribute.class("maintenance-page__message")], [
            html.text(message),
          ]),
          availability_retry_after_view(retry_after_seconds),
          html.div([attribute.class("maintenance-page__actions")], [
            html.a(
              [
                attribute.class("maintenance-page__link"),
                web_route.href(route.Public(route.Login)),
              ],
              [html.text("Login")],
            ),
            html.a(
              [
                attribute.class("maintenance-page__link"),
                web_route.href(route.Admin(route.AdminHome)),
              ],
              [html.text("Admin")],
            ),
          ]),
        ]),
      ]),
    ],
  )
}

fn document(
  config config: RenderConfig,
  title title: String,
  head_children head_children: List(element.Element(msg)),
  include_frontend include_frontend: Bool,
  ssr_data ssr_data: option.Option(json.Json),
  app_attributes app_attributes: List(attribute.Attribute(msg)),
  app_children app_children: List(element.Element(msg)),
) -> String {
  let base_head =
    list.append(
      [
        html.meta([attribute.charset("utf-8")]),
        html.meta([
          attribute.name("viewport"),
          attribute.content("width=device-width, initial-scale=1"),
        ]),
        html.meta([
          attribute.name("color-scheme"),
          attribute.content("light dark"),
        ]),
        html.meta([
          attribute.name("theme-color"),
          attribute.content("#111827"),
        ]),
        html.meta([
          attribute.name("referrer"),
          attribute.content("strict-origin-when-cross-origin"),
        ]),
        html.meta([
          attribute.name("format-detection"),
          attribute.content("telephone=no"),
        ]),
        html.link([
          attribute.rel("icon"),
          attribute.type_("image/svg+xml"),
          attribute.href("/static/favicon.svg"),
        ]),
        html.link([
          attribute.rel("manifest"),
          attribute.href("/static/site.webmanifest"),
        ]),
        html.title([], title),
        html.link([
          attribute.rel("stylesheet"),
          attribute.href(config.stylesheet_href),
        ]),
      ],
      list.map(config.additional_stylesheet_hrefs, fn(href) {
        html.link([attribute.rel("stylesheet"), attribute.href(href)])
      }),
    )
  let tail_head = case include_frontend {
    True ->
      list.append(
        list.map(config.frontend_preloads, fn(src) {
          html.link([
            attribute.rel("modulepreload"),
            attribute.href(src),
          ])
        }),
        [
          html.script(
            [
              attribute.type_("module"),
              attribute.src(config.frontend_src),
            ],
            "",
          ),
        ],
      )
    False -> []
  }
  let html_attributes = case config.theme {
    option.Some(theme) -> [
      attribute.lang("en"),
      attribute.data("theme", theme),
    ]
    option.None -> [attribute.lang("en")]
  }
  let ssr_data_elements = case ssr_data {
    option.Some(data) -> [ssr_data_view.view(data)]
    option.None -> []
  }

  html.html(html_attributes, [
    html.head([], list.append(base_head, list.append(head_children, tail_head))),
    html.body([], [
      html.div([attribute.id("app"), ..app_attributes], app_children),
      ..ssr_data_elements
    ]),
  ])
  |> element.to_document_string
}

fn availability_retry_after_view(
  retry_after_seconds: option.Option(Int),
) -> element.Element(Nil) {
  case retry_after_seconds {
    option.Some(seconds) ->
      html.p([attribute.class("maintenance-page__message")], [
        html.text(
          "Please try again in about " <> retry_after_text(seconds) <> ".",
        ),
      ])
    option.None ->
      html.p([attribute.class("maintenance-page__message")], [
        html.text("Please try again shortly."),
      ])
  }
}

fn retry_after_text(seconds: Int) -> String {
  case seconds >= 3600 {
    True -> int.to_string(seconds / 3600) <> " hour(s)"
    False ->
      case seconds >= 60 {
        True -> int.to_string(seconds / 60) <> " minute(s)"
        False -> int.to_string(seconds) <> " second(s)"
      }
  }
}
