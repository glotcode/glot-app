import gleam/list
import gleam/option
import glot_core/route
import glot_web/build_info.{type BuildInfo}
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  account_route account_route: route.Route,
  build_info build_info: option.Option(BuildInfo),
) -> Element(msg) {
  html.footer([attribute.class("site-footer")], [
    html.nav(
      [
        attribute.class("site-footer__nav"),
        attribute.attribute("aria-label", "Footer"),
      ],
      list.append(
        [
          html.div([attribute.class("site-footer__links")], [
            html.a([web_route.href(route.Public(route.Home))], [
              html.text("Home"),
            ]),
            html.a(
              [
                web_route.href(
                  route.Public(route.Snippets(
                    option.None,
                    option.None,
                    option.None,
                  )),
                ),
              ],
              [html.text("Public snippets")],
            ),
            html.a([web_route.href(account_route)], [html.text("Account")]),
            html.a([web_route.href(route.Public(route.Contact))], [
              html.text("Contact"),
            ]),
            html.a([web_route.href(route.Public(route.Privacy))], [
              html.text("Privacy"),
            ]),
            html.button(
              [
                attribute.type_("button"),
                attribute.class("site-footer__link-button"),
                attribute.data("cookie-notice-settings", ""),
              ],
              [html.text("Cookie notice")],
            ),
          ]),
        ],
        commit_link(build_info),
      ),
    ),
  ])
}

fn commit_link(build: option.Option(BuildInfo)) -> List(Element(msg)) {
  case build {
    option.Some(build) -> [
      html.a(
        [
          attribute.class("site-footer__version"),
          attribute.href(build_info.commit_url(build)),
          attribute.attribute("target", "_blank"),
          attribute.attribute("rel", "noopener noreferrer"),
          attribute.title("View this version on GitHub"),
        ],
        [html.text(build_info.short_commit(build))],
      ),
    ]
    option.None -> []
  }
}
